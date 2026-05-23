#!/usr/bin/env bash
# Bootstrap a NixOS host from the installer ISO.
#
# Interactive end-to-end: prompts for host, user, disk, swap, and password;
# partitions, formats, mounts, installs NixOS, activates home-manager.
#
# Prerequisites:
#   1. Booted into a NixOS installer ISO with internet access.
#   2. The target host is defined in flake.nix + hosts/<host>/configuration.nix
#      with a matching homeConfigurations.<user>@<host>. A placeholder
#      hardware-configuration.nix is fine — this script overwrites it.
#
# Usage:
#   curl -fsSL <raw-url>/bootstrap.sh | sh
#
# Env overrides (skip the corresponding prompt):
#   NIX_HOST=elysium  NIX_USER=icorbrey  REPO_URL=...

set -euo pipefail

REPO_URL=${REPO_URL:-https://tangled.org/isaaccorbrey.com/dotnix}

main() {
  # Reattach stdin to the tty so `curl | sh` doesn't starve gum of input.
  [ -t 0 ] || exec < /dev/tty

  if ! command -v gum >/dev/null 2>&1; then
    echo "==> Fetching gum..."
    PATH="$(nix build --no-link --print-out-paths nixpkgs#gum)/bin:$PATH"
  fi

  gum style --bold --foreground 51 "NixOS bootstrap"

  local host user target
  host=${NIX_HOST:-$(pick_host)}
  user=${NIX_USER:-$(pick_user "$host")}
  target=/mnt/home/$user/.nix

  gum style --faint "host=$host  user=$user  target=$target"

  local skip_partition=
  if mountpoint -q /mnt; then
    if gum confirm "/mnt is already mounted. Use as-is and skip partitioning?"; then
      skip_partition=1
    fi
  fi
  [ -z "$skip_partition" ] && partition_disk

  gum style --bold "Set password for $user"
  local user_password user_password2
  while :; do
    user_password=$(gum input --password --header "Password:")
    user_password2=$(gum input --password --header "Confirm:")
    if [ -z "$user_password" ]; then
      gum style --foreground 196 "Password can't be empty."
      continue
    fi
    [ "$user_password" = "$user_password2" ] && break
    gum style --foreground 196 "Passwords didn't match — try again."
  done

  gum style --bold "Cloning $REPO_URL → $target"
  mkdir -p "$(dirname "$target")"
  if [ -d "$target/.git" ]; then
    gum style --faint "$target already exists, reusing existing clone."
  elif [ -e "$target" ]; then
    gum style --foreground 196 "$target exists but isn't a git repo. Aborting."
    exit 1
  else
    git clone "$REPO_URL" "$target"
  fi

  cd "$target"

  if [ ! -f "hosts/$host/configuration.nix" ]; then
    gum style --foreground 196 "No configuration found at hosts/$host/configuration.nix"
    exit 1
  fi

  gum style --bold "Generating hardware-configuration.nix"
  nixos-generate-config --root /mnt --show-hardware-config \
    > "hosts/$host/hardware-configuration.nix"

  gum style --bold "Installing NixOS"
  nixos-install --root /mnt --flake "path:.#$host" --no-root-passwd

  gum style --bold "Setting ownership on /home/$user"
  nixos-enter --root /mnt --command "chown -R $user:users /home/$user"

  gum style --bold "Setting $user's password"
  printf '%s:%s\n' "$user" "$user_password" \
    | nixos-enter --root /mnt --command 'chpasswd'
  unset user_password user_password2

  gum style --bold "Activating home-manager for $user@$host"
  local hm_script=/mnt/tmp/hm-activate.sh
  cat > "$hm_script" <<HM
#!/usr/bin/env bash
set -euo pipefail

# systemd isn't running in this chroot, so socket activation won't start the
# nix daemon for us. Launch it manually so the unprivileged user's nix build
# and profile updates during activation have a store socket to talk to.
nix-daemon &
daemon_pid=\$!
trap 'kill \$daemon_pid 2>/dev/null || true' EXIT
for _ in 1 2 3 4 5 6 7 8 9 10; do
  [ -S /nix/var/nix/daemon-socket/socket ] && break
  sleep 0.2
done

su - $user <<'USR'
set -euo pipefail
cd /home/$user/.nix
act=\$(nix build --no-link --print-out-paths '.#homeConfigurations."$user@$host".activationPackage')
"\$act/activate"
USR
HM
  chmod +x "$hm_script"
  nixos-enter --root /mnt --command /tmp/hm-activate.sh
  rm -f "$hm_script"

  gum style --bold "Initializing jj colocated repo at /home/$user/.nix"
  # Fresh `su -` so PATH picks up jj from the user's home-manager session vars.
  # Idempotent: skip if .jj already exists (re-run scenario).
  nixos-enter --root /mnt --command \
    "su - $user -c 'cd ~/.nix && [ -d .jj ] || jj git init --colocate'"

  gum style --bold --foreground 46 "Install complete."
  cat <<EOF

NixOS + home-manager are both activated; the repo is at /home/$user/.nix.

After reboot:
  - Run \`nix develop\` in ~/.nix for the full toolchain.
  - Commit + push the new hosts/$host/hardware-configuration.nix.
EOF
}

pick_host() {
  local hosts
  hosts=$(
    nix eval --raw --apply \
      'cfgs: builtins.concatStringsSep "\n" (builtins.attrNames cfgs)' \
      "git+$REPO_URL#nixosConfigurations"
  )
  if [ -z "$hosts" ]; then
    gum style --foreground 196 "No nixosConfigurations found in the flake." >&2
    exit 1
  fi
  echo "$hosts" | gum choose --header "Select a host:"
}

pick_user() {
  local host=$1 users count
  users=$(
    nix eval --raw --apply \
      'cfgs: builtins.concatStringsSep "\n" (builtins.attrNames cfgs)' \
      "git+$REPO_URL#homeConfigurations" \
      | awk -F@ -v h="$host" '$2 == h { print $1 }'
  )
  if [ -z "$users" ]; then
    gum style --foreground 196 "No homeConfigurations matching @$host" >&2
    exit 1
  fi
  count=$(echo "$users" | wc -l)
  if [ "$count" -eq 1 ]; then
    echo "$users"
  else
    echo "$users" | gum choose --header "Select a user for $host:"
  fi
}

pick_swap_size() {
  # Returns swap size in GiB as an integer (0 = none).
  #
  # Swap serves two independent purposes:
  #   1. OOM buffer for normal operation. 2 × RAM if RAM ≤ 4 GiB (low-RAM
  #      systems OOM fastest); else 8 GiB (diminishing returns past that).
  #   2. Hibernation dump area, sized to RAM. Only needed if you actually
  #      hibernate, and additive with (1) — you don't want hibernating to
  #      eat your OOM headroom.
  #
  # Auto · safe default  : OOM buffer only.
  # Auto · hibernation   : OOM buffer + RAM-sized dump area.
  # Manual               : user enters a number.
  # None                 : 0.
  local mode ram_gb safe_gb hib_gb val
  ram_gb=$(awk '/^MemTotal:/ { printf "%d", ($2 + 1048575) / 1048576 }' /proc/meminfo)
  safe_gb=$(( ram_gb <= 4 ? ram_gb * 2 : 8 ))
  hib_gb=$(( safe_gb + ram_gb ))

  mode=$(printf '%s\n' \
    "Auto · ${safe_gb} GiB · no hibernation" \
    "Auto · ${hib_gb} GiB · supports hibernation" \
    "Manual" \
    "None" \
    | gum choose --header "Swap configuration (detected ${ram_gb} GiB RAM):")

  case "$mode" in
    "Auto · ${safe_gb} GiB · no"*)
      echo "$safe_gb"
      ;;
    "Auto · ${hib_gb} GiB · supports"*)
      echo "$hib_gb"
      ;;
    "Manual")
      val=$(gum input --header "Swap size in GiB" --placeholder "16")
      val=${val%%[!0-9]*}
      echo "${val:-0}"
      ;;
    *)
      echo 0
      ;;
  esac
}

detect_boot_disk() {
  # NixOS installer mounts the live ISO at /iso when booted from removable media.
  # Trace that back to the parent disk so we can flag it in the disk picker.
  local src parent
  src=$(findmnt -no SOURCE /iso 2>/dev/null) || return 0
  [ -n "$src" ] || return 0
  parent=$(lsblk -no PKNAME "$src" 2>/dev/null | head -1) || return 0
  [ -n "$parent" ] && echo "/dev/$parent"
}

partition_disk() {
  gum style --bold "Disk setup"

  local disk_line disk boot_disk part_prefix swap_gb swap_end boot_part swap_part root_part
  boot_disk=$(detect_boot_disk)

  disk_line=$(
    lsblk -d -n -p -o NAME,SIZE,MODEL,TYPE \
      | awk -v boot="$boot_disk" '$NF=="disk" {
          sub(/[[:space:]]+disk$/, "");
          if (boot != "" && $1 == boot) print $0 "  ← booted from this";
          else print;
        }' \
      | gum choose --header "Select the target disk (will be wiped):"
  )
  disk=$(echo "$disk_line" | awk '{print $1}')

  if [ -n "$boot_disk" ] && [ "$disk" = "$boot_disk" ]; then
    gum style --foreground 196 --bold "$disk is the disk you booted from."
    gum confirm --default=false "Really wipe the installer media?" \
      || { echo "Aborted."; exit 1; }
  fi

  swap_gb=$(pick_swap_size)

  gum style --foreground 196 --bold "About to WIPE $disk"
  gum style "Layout: 1 GiB EFI · $swap_gb GiB swap · remainder ext4 root"
  gum confirm "Proceed?" || { echo "Aborted."; exit 1; }

  case "$disk" in
    /dev/nvme*|/dev/mmcblk*|/dev/loop*) part_prefix=p ;;
    *) part_prefix= ;;
  esac

  swapoff -a 2>/dev/null || true
  umount -R /mnt 2>/dev/null || true
  wipefs -a -f "$disk"

  parted -s "$disk" -- mklabel gpt
  parted -s "$disk" -- mkpart ESP fat32 1MiB 1GiB
  parted -s "$disk" -- set 1 esp on
  if [ "$swap_gb" -gt 0 ]; then
    swap_end=$((1 + swap_gb))
    parted -s "$disk" -- mkpart primary linux-swap 1GiB "${swap_end}GiB"
    parted -s "$disk" -- mkpart primary ext4 "${swap_end}GiB" 100%
    boot_part="${disk}${part_prefix}1"
    swap_part="${disk}${part_prefix}2"
    root_part="${disk}${part_prefix}3"
  else
    parted -s "$disk" -- mkpart primary ext4 1GiB 100%
    boot_part="${disk}${part_prefix}1"
    swap_part=
    root_part="${disk}${part_prefix}2"
  fi

  partprobe "$disk" || true
  udevadm settle

  mkfs.fat -F 32 "$boot_part"
  mkfs.ext4 -F "$root_part"
  if [ -n "$swap_part" ]; then
    mkswap "$swap_part"
    swapon "$swap_part"
  fi

  mount "$root_part" /mnt
  mkdir -p /mnt/boot
  mount "$boot_part" /mnt/boot
}

main "$@"

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
#   curl -fsSL <raw-url>/bootstrap.sh | sudo sh
#
# Env overrides (skip the corresponding prompt):
#   NIX_HOST=elysium  NIX_USER=icorbrey  REPO_URL=...

set -euo pipefail

# The installer ISO ships with a minimal nix.conf — opt into the
# experimental features the rest of this script (and the flake) relies on.
export NIX_CONFIG="experimental-features = nix-command flakes"

REPO_URL=${REPO_URL:-https://tangled.org/isaaccorbrey.com/dotnix}

# ANSI styles, used by run_quiet's spinner/preview and ensure_gum (both run
# before gum is necessarily available, so they can't use gum styling).
RESET=$'\033[0m'
BOLD=$'\033[1m'
DIM=$'\033[2m'
MAGENTA=$'\033[35m'
RED=$'\033[31m'

# run_quiet TITLE -- COMMAND [ARGS...]
#
# Runs COMMAND inside a PTY (via util-linux `script`) while showing a spinner
# and the last PREVIEW_LINES (default 5) of output beneath it. On success the
# live area collapses to a single styled title line; on failure the full
# captured output is printed and COMMAND's exit code is returned. Mirrors
# scripts/run-quiet, but inlined here because the installer doesn't have the
# repo cloned yet.
#
# Depends on gum being on PATH (for the success/failure summary lines), so
# ensure_gum must be called before any run_quiet invocation.
run_quiet() {
  local title=$1
  shift
  if [ "${1:-}" != "--" ]; then
    printf 'run_quiet: expected "--" after TITLE\n' >&2
    return 2
  fi
  shift

  local preview_lines=${PREVIEW_LINES:-5}
  local log pid=""
  log=$(mktemp)

  # Sub-shell-safe trap that references the locals above; cleared on success.
  trap 'if [ -n "${pid:-}" ]; then kill "$pid" 2>/dev/null || :; wait "$pid" 2>/dev/null || :; fi; tput cnorm 2>/dev/null || :; rm -f "$log"' INT TERM

  tput civis 2>/dev/null || true

  local frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
  local n_frames=${#frames[@]}
  local total=$((preview_lines + 1))
  local back=$((total - 1))
  local prefix="${DIM}│${RESET} "
  local prefix_width=2

  # Pull leading sudo (+ its short flags) out so it runs in the caller's real
  # tty (cache hit) instead of inside the new PTY (where it has no stdin).
  local sudo_prefix=()
  if [ "${1:-}" = "sudo" ]; then
    sudo_prefix+=("$1"); shift
    while [ $# -gt 0 ] && [[ "${1}" == -* ]]; do
      sudo_prefix+=("$1"); shift
    done
  fi

  local arg cmd_str=""
  for arg in "$@"; do
    cmd_str+="$(printf '%q ' "$arg")"
  done

  # Reserve vertical space and park the cursor at the top of the live area.
  local i
  for ((i = 0; i < back; i++)); do echo; done
  printf '\033[%dA\r' "$back"

  # -q quiet, -e propagate exit status, -f flush each write, -c command,
  # /dev/null discards the typescript.
  "${sudo_prefix[@]}" script -qefc "$cmd_str" /dev/null > "$log" 2>&1 &
  pid=$!

  local frame=0 cols content_cols title_cols spin raw_title title_padded
  while kill -0 "$pid" 2>/dev/null; do
    cols=$(tput cols 2>/dev/null || echo 80)
    content_cols=$((cols - prefix_width))
    title_cols=$((cols - 2))
    [ "$content_cols" -lt 1 ] && content_cols=1
    [ "$title_cols" -lt 1 ] && title_cols=1

    spin=${frames[$((frame % n_frames))]}
    raw_title=${title:0:title_cols}
    title_padded=$(printf '%-*s' "$title_cols" "$raw_title")
    printf '%s%s%s %s%s%s\n' \
      "$MAGENTA" "$spin" "$RESET" \
      "$BOLD" "$title_padded" "$RESET"

    # Normalize line endings: strip trailing \r (from CRLF), then convert any
    # standalone \r (progress-bar updates) to \n.
    sed 's/\r$//' "$log" | tr '\r' '\n' \
      | awk -v max="$content_cols" \
            -v prefix="$prefix" \
            -v dim="$DIM" \
            -v reset="$RESET" \
            -v n="$preview_lines" '
        function fit(s, m,    out, vis, i, c, len, j, esc) {
          out = ""; vis = 0; esc = ""
          len = length(s)
          for (i = 1; i <= len; i++) {
            c = substr(s, i, 1)
            if (esc != "") {
              esc = esc c
              if (c ~ /[A-Za-z]/) {
                if (c == "m") out = out esc dim
                esc = ""
              }
            } else if (c == "\033") {
              esc = c
            } else {
              if (vis >= m) break
              out = out c; vis++
            }
          }
          for (j = vis; j < m; j++) out = out " "
          return out
        }
        # Skip lines that are empty/whitespace-only after stripping ANSI.
        {
          v = $0
          gsub(/\033\[[0-9;]*[a-zA-Z]/, "", v)
          if (v ~ /^[[:space:]]*$/) next
          lines[count++] = $0
        }
        END {
          empty = ""
          for (j = 0; j < max; j++) empty = empty " "
          start = count > n ? count - n : 0
          shown = count - start
          for (i = 0; i < n; i++) {
            nl = (i < n - 1 ? "\n" : "")
            if (i < shown) {
              printf "%s%s%s%s%s", prefix, dim, fit(lines[start + i], max), reset, nl
            } else {
              printf "%s%s%s", prefix, empty, nl
            }
          }
        }
      '

    printf '\033[%dA\r' "$back"
    frame=$((frame + 1))
    sleep 0.1
  done

  local ret=0
  wait "$pid" || ret=$?
  pid=""

  # Wipe the live area, restore the cursor, drop our trap.
  printf '\r\033[J'
  tput cnorm 2>/dev/null || true
  trap - INT TERM

  if [ "$ret" -ne 0 ]; then
    gum log --level error "$title (exit $ret)"
    sed 's/\r$//' "$log" | gum pager
    rm -f "$log"
    return "$ret"
  fi

  gum log --level info "$title"
  rm -f "$log"
  return 0
}

# Ensure gum is on PATH. The installer ISO often ships an older gum (or none
# at all), so we always pin to nixpkgs#gum — that way prompts, styling, and
# run_quiet's log output all behave the same everywhere.
#
# This runs *before* run_quiet, so we can't use it to show progress here.
# `nix build` is quiet enough on success that a plain status line is fine.
ensure_gum() {
  if command -v gum >/dev/null 2>&1; then
    return
  fi
  printf '%s::%s %sFetching gum from nixpkgs...%s\n' \
    "$MAGENTA" "$RESET" "$BOLD" "$RESET"
  local gum_link=/tmp/bootstrap-gum
  if ! nix build --out-link "$gum_link" nixpkgs#gum; then
    printf '%sFailed to fetch gum from nixpkgs.%s\n' "$RED" "$RESET" >&2
    exit 1
  fi
  PATH="$gum_link/bin:$PATH"
}

main() {
  # Reattach stdin to the tty so `curl | sh` doesn't starve gum of input.
  [ -t 0 ] || exec < /dev/tty

  ensure_gum

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

  mkdir -p "$(dirname "$target")"
  if [ -d "$target/.git" ]; then
    gum style --faint "$target already exists, reusing existing clone."
  elif [ -e "$target" ]; then
    gum style --foreground 196 "$target exists but isn't a git repo. Aborting."
    exit 1
  else
    run_quiet "Cloning $REPO_URL → $target" -- git clone "$REPO_URL" "$target"
  fi

  cd "$target"

  if [ ! -f "hosts/$host/configuration.nix" ]; then
    gum style --foreground 196 "No configuration found at hosts/$host/configuration.nix"
    exit 1
  fi

  run_quiet "Generating hosts/$host/hardware-configuration.nix" -- \
    bash -c "nixos-generate-config --root /mnt --show-hardware-config > 'hosts/$host/hardware-configuration.nix'"

  run_quiet "Installing NixOS (#$host)" -- \
    nixos-install --root /mnt --flake "path:.#$host" --no-root-passwd

  run_quiet "Setting ownership on /home/$user" -- \
    nixos-enter --root /mnt --command "chown -R $user:users /home/$user"

  # chpasswd needs stdin, so we can't wrap it through the PTY in run_quiet.
  # It's near-instant anyway — just run it bare with a header.
  gum style --bold "Setting $user's password"
  printf '%s:%s\n' "$user" "$user_password" \
    | nixos-enter --root /mnt --command 'chpasswd'
  unset user_password user_password2

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
# The user's profile isn't populated yet, so git isn't on PATH — but nix
# needs it to read the local flake. Pull it from nixpkgs for this one call.
PATH="\$(nix build --no-link --print-out-paths nixpkgs#git)/bin:\$PATH"
act=\$(nix build --no-link --print-out-paths '.#homeConfigurations."$user@$host".activationPackage')
"\$act/activate"
USR
HM
  chmod +x "$hm_script"
  run_quiet "Activating home-manager for $user@$host" -- \
    nixos-enter --root /mnt --command /tmp/hm-activate.sh
  rm -f "$hm_script"

  # Fresh `su -` so PATH picks up jj from the user's home-manager session vars.
  # Idempotent: skip if .jj already exists (re-run scenario).
  run_quiet "Initializing jj colocated repo at /home/$user/.nix" -- \
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

partition_disk() {
  gum style --bold "Disk setup"

  local disk_line disk part_prefix swap_gb swap_end boot_part swap_part root_part

  disk_line=$(
    lsblk -d -n -p -o NAME,SIZE,MODEL,TYPE \
      | gum choose --header "Select the target disk (will be wiped):"
  )
  disk=$(echo "$disk_line" | awk '{print $1}')

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

  run_quiet "Wiping signatures on $disk" -- wipefs -a -f "$disk"

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

  run_quiet "Formatting EFI partition ($boot_part)" -- mkfs.fat -F 32 "$boot_part"
  run_quiet "Formatting root partition ($root_part)" -- mkfs.ext4 -F "$root_part"
  if [ -n "$swap_part" ]; then
    run_quiet "Formatting swap partition ($swap_part)" -- mkswap "$swap_part"
    swapon "$swap_part"
  fi

  mount "$root_part" /mnt
  mkdir -p /mnt/boot
  mount "$boot_part" /mnt/boot
}

main "$@"

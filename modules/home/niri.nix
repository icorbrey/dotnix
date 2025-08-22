{ config, lib, pkgs, niri, ... }: {
  options.modules.home.niri = {
    enable = lib.mkEnableOption "niri";
    enableGdmHelpers = lib.mkEnableOption
      "Scripts to set up Niri with GDM on HM only";

    renderDevice = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = "null";
    };
  };

  imports = [niri.homeModules.niri];

  config = let
    wayland = config.modules.home.wayland;
    global = config.modules.home.global;
    niri = config.modules.home.niri;
  in lib.mkIf niri.enable {
    programs.niri.enable = true;
    programs.niri.package = pkgs.niri-stable;
    programs.niri.config = lib.concatStringsSep "\n\n" [
      ''
        spawn-at-startup "waybar"
        spawn-at-startup "mako"

        binds {
          Super+Return { spawn "${global.terminal}"; }
          Mod+D { spawn "fuzzel"; }
          Mod+Shift+E { quit; }
          Mod+Shift+Slash { show-hotkey-overlay; }
        }
      ''
      (lib.optionalString (niri.renderDevice != null) ''
        debug { render-drm-device "${niri.renderDevice}"; }
      '')
      (lib.optionalString wayland.enable ''
        environment {
          ELECTRON_OZONE_PLATFORM_HINT "wayland"
          NIXOS_OZONE_WL "1"
        }
      '')
    ];
    
    # TODO: Move to waybar.nix
    programs.waybar.enable = true;
    programs.waybar.systemd.enable = true;
    programs.waybar.settings = {
      mainBar.layer = "top";
    };
    
    programs.swaylock.enable = true;
    programs.fuzzel.enable = true;

    services.mako.enable = true;

    xdg.configFile."systemd/user/niri.service".source =
      "${config.programs.niri.package}/lib/systemd/user/niri.service";
    xdg.configFile."systemd/user/niri-shutdown.target".source =
      "${config.programs.niri.package}/lib/systemd/user/niri-shutdown.target";
      
    home.packages = lib.mkIf niri.enableGdmHelpers [
      (pkgs.writeShellScriptBin "niri-gdm-install" ''
        set -euo pipefail

        # Find the .desktop shipped by niri in the Nix store.
        niri_bin="$(command -v niri)"
        if [ -z "''${niri_bin:-}" ]; then
          echo "niri not found in PATH; make sure programs.niri.package is installed." >&2
          exit 1
        fi
        store_bin="$(readlink -f "$niri_bin")"
        desktop_src="$(dirname "$store_bin")/../share/wayland-sessions/niri.desktop"

        if [ ! -f "$desktop_src" ]; then
          echo "Could not find niri.desktop next to $store_bin" >&2
          exit 1
        fi

        echo "Installing session entry to /usr/local/share/wayland-sessions/niri.desktop ..."
        sudo install -Dm644 "$desktop_src" /usr/local/share/wayland-sessions/niri.desktop

        echo "Installing wrapper /usr/local/bin/niri-session (points to your Nix profile) ..."
        # Use a wrapper so upgrades don't require reinstalling the .desktop.
        cat <<'EOF' | sudo tee /usr/local/bin/niri-session >/dev/null
        #!/bin/sh
        exec "$HOME/.nix-profile/bin/niri-session" "$@"
        EOF
        sudo chmod +x /usr/local/bin/niri-session

        echo "Done. Log out, click the gear in GDM, and choose “Niri”."
        echo "Note: GDM needs Wayland enabled (see /etc/gdm3/custom.conf: WaylandEnable=true)."
      '')

      (pkgs.writeShellScriptBin "niri-gdm-uninstall" ''
        set -euo pipefail
        echo "Removing /usr/local/share/wayland-sessions/niri.desktop (if present) ..."
        sudo rm -f /usr/local/share/wayland-sessions/niri.desktop
        echo "Removing /usr/local/bin/niri-session (if present) ..."
        sudo rm -f /usr/local/bin/niri-session
        echo "Done."
      '')
    ];
  };
}

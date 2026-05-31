{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.home.gtk;
  dms = config.modules.home.dank-material-shell;
in {
  options.modules.home.gtk = {
    enable = lib.mkEnableOption "gtk";

    iconTheme = {
      name = lib.mkOption {
        type = lib.types.str;
        default = "WhiteSur-dark";
        description = ''
          Name of the icon theme directory under share/icons. Must match a
          subdirectory shipped by `iconTheme.package` (e.g. "WhiteSur",
          "WhiteSur-dark", "WhiteSur-light").
        '';
      };

      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.whitesur-icon-theme;
        defaultText = lib.literalExpression "pkgs.whitesur-icon-theme";
        description = "Package providing the icon theme.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    gtk = {
      enable = true;
      iconTheme = {
        inherit (cfg.iconTheme) name package;
      };
    };

    # Make Qt apps (DankMaterialShell / Quickshell, etc.) read GTK settings
    # so QIcon::fromTheme resolves against the same theme as everything else.
    # Without this, Qt's icon theme falls back to "hicolor" and SNI tray
    # entries advertised by name (e.g. Spotify's "spotify-client") render
    # as a missing-texture placeholder.
    qt = {
      enable = true;
      platformTheme.name = "gtk";
    };

    # DankMaterialShell stores the bar's icon theme in its own settings
    # file as the "iconTheme" key; "System Default" is unreliable across
    # Quickshell versions, so pin it explicitly to the configured theme.
    # Deep-merge to preserve any host-managed keys (lockScreenActiveMonitor,
    # etc.) and trigger a restart so the change applies on activation.
    home.activation.dmsIconThemeOverride =
      lib.mkIf dms.enable
      (lib.hm.dag.entryAfter ["writeBoundary" "mergeDmsHostSettings"] ''
        config_dir="''${XDG_CONFIG_HOME:-$HOME/.config}"
        target="$config_dir/DankMaterialShell/settings.json"
        mkdir -p "$(dirname "$target")"
        if [ ! -f "$target" ] || ! ${pkgs.jq}/bin/jq -e . "$target" >/dev/null 2>&1; then
          printf '{}\n' > "$target"
        fi
        tmp="$(mktemp)"
        ${pkgs.jq}/bin/jq --arg t ${lib.escapeShellArg cfg.iconTheme.name} \
          '. + {iconTheme: $t}' "$target" > "$tmp"
        mv "$tmp" "$target"
        if command -v systemctl >/dev/null 2>&1; then
          systemctl --user try-restart dms 2>/dev/null || true
        fi
      '');
  };
}

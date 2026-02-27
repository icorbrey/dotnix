{
  config,
  lib,
  options,
  ...
}: {
  options.modules.home.dank-material-shell = {
    enable = lib.mkEnableOption "DankMaterialShell";
    plugins = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to install DMS plugins shipped in this repo.";
      };
    };
  };

  config = let
    dms = config.modules.home.dank-material-shell;
    niri = config.modules.home.niri.enable;
    enablePlugins = dms.plugins.enable && niri;
  in
    lib.mkIf dms.enable (
      lib.optionalAttrs (lib.hasAttrByPath ["programs" "dank-material-shell"] options) {
        programs.dank-material-shell = {
          enable = true;
          systemd.enable = true;
        };

        systemd.user.services.dms = lib.mkIf niri {
          Unit.ConditionEnvironment = [
            "XDG_CURRENT_DESKTOP=niri"
            "XDG_SESSION_DESKTOP=niri"
            "DESKTOP_SESSION=niri"
          ];
        };

        xdg.configFile = lib.mkIf enablePlugins {
          "DankMaterialShell/plugins/niri-cursor-speed/plugin.json".source =
            ./plugin/niri-cursor-speed/plugin.json;
          "DankMaterialShell/plugins/niri-cursor-speed/NiriCursorSpeed.qml".source =
            ./plugin/niri-cursor-speed/NiriCursorSpeed.qml;
          "DankMaterialShell/plugins/niri-cursor-speed/NiriCursorSpeedSettings.qml".source =
            ./plugin/niri-cursor-speed/NiriCursorSpeedSettings.qml;
        };

        systemd.user.tmpfiles.rules = lib.mkIf enablePlugins [
          "d %h/.config/niri 0755 - - -"
          "f %h/.config/niri/dms-input.kdl 0644 - - -"
        ];

        home.activation.ensureDmsPluginState = lib.mkIf enablePlugins (
          lib.hm.dag.entryAfter ["writeBoundary"] ''
            config_dir="''${XDG_CONFIG_HOME:-$HOME/.config}"
            if [ ! -f "$config_dir/niri/dms-input.kdl" ]; then
              mkdir -p "$config_dir/niri"
              : > "$config_dir/niri/dms-input.kdl"
            fi
          ''
        );

        home.activation.clearDmsPluginQmlCache = lib.mkIf enablePlugins (
          lib.hm.dag.entryAfter ["writeBoundary"] ''
            cache_dir="''${XDG_CACHE_HOME:-$HOME/.cache}"
            if command -v systemctl >/dev/null 2>&1; then
              systemctl --user stop dms || true
            fi
            rm -rf "$cache_dir/quickshell/qmlcache"
            rm -rf "$cache_dir/quickshell"/qtpipelinecache-*
            if command -v systemctl >/dev/null 2>&1; then
              systemctl --user start dms || true
            fi
          ''
        );
      }
    );
}

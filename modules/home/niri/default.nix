{
  config,
  lib,
  pkgs,
  ...
}: {
  options.modules.home.niri = {
    enable = lib.mkEnableOption "Niri";

    hostConfigFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Optional absolute or relative path to a host-specific Niri KDL fragment.";
    };
  };

  config = let
    niri = config.modules.home.niri;
    selectedHost = config.modules.home.global.hostName;
    dmsPluginInclude =
      config.modules.home.dank-material-shell.enable
      && config.modules.home.dank-material-shell.plugins.enable;
    # When wallpaper-engine is enabled, push DMS's background-layer Quickshell
    # surface into niri's overview backdrop so linux-wallpaperengine (on the
    # bottom layer) is the visible desktop wallpaper while DMS's wallpaper
    # shows behind/between workspaces in the overview. On hosts without
    # wallpaper-engine, DMS renders directly on the desktop instead.
    wallpaperEngineEnabled =
      (config.modules.home.wallpaper-engine.enable or false);

    hostSnippet = let
      candidate =
        if selectedHost != null
        then ../../../hosts/${selectedHost}/niri/config.kdl
        else null;
    in
      if niri.hostConfigFile != null
      then niri.hostConfigFile
      else if candidate != null && builtins.pathExists candidate
      then candidate
      else null;

    combinedConfig =
      builtins.readFile ./config.kdl
      + lib.optionalString (hostSnippet != null)
      ("\n\n// Host-specific overrides\n" + builtins.readFile hostSnippet)
      + lib.optionalString wallpaperEngineEnabled ''

// Put DMS's static wallpaper (background-layer Quickshell surface) into the
// niri overview backdrop. linux-wallpaperengine sits on the bottom layer
// above this and continues to render as the desktop wallpaper and inside
// workspace thumbnails; DMS's wallpaper shows behind/between workspaces in
// the overview. Applied only on hosts where wallpaper-engine is enabled.
//
// The matcher is intentionally narrow: only the background-layer surface
// with namespace "quickshell". DMS's bar, OSDs, etc. use other namespaces
// (e.g. "dms:bar") and are unaffected. Verify with `niri msg layers`.
layer-rule {
    match namespace="^quickshell$" layer="background"
    place-within-backdrop true
}
''
      + lib.optionalString dmsPluginInclude ''

// DMS plugin overrides.
// Note: pointing device sections in `input` are non-merging, so keep any mouse/touchpad
// overrides in the included file to avoid conflicts.
include "dms-input.kdl"
'';
  in
    lib.mkIf niri.enable {
      home.packages = [
        pkgs.xwayland-satellite
        pkgs.wl-clipboard
        pkgs.brightnessctl
        pkgs.playerctl
        pkgs.swayidle
      ];

      xdg.configFile."niri/config.kdl".text = combinedConfig;
      xdg.configFile."niri/swayidle.sh" = {
        source = ./swayidle.sh;
        executable = true;
      };
    };
}

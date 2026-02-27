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
        pkgs.swayidle
      ];

      xdg.configFile."niri/config.kdl".text = combinedConfig;
      xdg.configFile."niri/swayidle.sh" = {
        source = ./swayidle.sh;
        executable = true;
      };
    };
}

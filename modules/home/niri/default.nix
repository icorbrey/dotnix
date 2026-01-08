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
      ("\n\n// Host-specific overrides\n" + builtins.readFile hostSnippet);
  in
    lib.mkIf niri.enable {
      home.packages = [
        pkgs.xwayland-satellite
        pkgs.wl-clipboard
        pkgs.brightnessctl
        pkgs.swayidle
      ];

      xdg.configFile."niri/config.kdl".text = combinedConfig;
    };
}

{
  config,
  lib,
  pkgs,
  ...
}: {
  options.modules.home.wayland = {
    enable = lib.mkEnableOption "wayland";
  };

  config = let
    wayland = config.modules.home.wayland;
  in
    lib.mkIf wayland.enable {
      home.packages = [
        pkgs.wl-clipboard
      ];
    };
}

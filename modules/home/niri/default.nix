{ config, lib, pkgs, ... }: {
  options.modules.home.niri = {
    enable = lib.mkEnableOption "Niri";
  };

  config = let niri = config.modules.home.niri;
    in lib.mkIf niri.enable {
      home.packages = [
        pkgs.xwayland-satellite
        pkgs.wl-clipboard
        pkgs.swaylock
        pkgs.fuzzel
        pkgs.swaybg
        pkgs.waybar
        pkgs.slurp
        pkgs.grim
        pkgs.mako
      ];

      xdg.configFile."niri/config.kdl".source = ./config.kdl;
    };
}

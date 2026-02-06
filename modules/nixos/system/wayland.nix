{
  config,
  lib,
  pkgs,
  ...
}: {
  options.modules.nixos.system.wayland = {
    enable = lib.mkEnableOption "wayland";
  };

  config = let
    wayland = config.modules.nixos.system.wayland;
  in
    lib.mkIf wayland.enable {
      programs.xwayland.enable = true;

      xdg.portal.enable = true;
      xdg.portal.extraPortals = [
        pkgs.xdg-desktop-portal-wlr
        pkgs.xdg-desktop-portal-gtk
      ];
      xdg.portal.config = {
        niri = {
          default = lib.mkForce ["wlr" "gtk"];
        };
      };
    };
}

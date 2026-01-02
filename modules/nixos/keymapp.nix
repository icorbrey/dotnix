{ config, lib, pkgs, ... }: {
  options.modules.nixos.keymapp = {
    enable = lib.mkEnableOption "Keymapp";
  };

  config = let keymapp = config.modules.nixos.keymapp;
    in lib.mkIf keymapp.enable {
      environment.systemPackages = [
        pkgs.wally-cli
        pkgs.dfu-util
        pkgs.usbutils
        pkgs.keymapp
      ];

      services.udev.packages = [
        pkgs.zsa-udef-rules
      ];
    };
}

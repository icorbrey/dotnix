{
  config,
  lib,
  ...
}: {
  options.modules.nixos.system.bootloader = {
    systemd.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
  };

  config = let
    inherit (config.modules.nixos.system) bootloader;
  in {
    boot.loader.efi.canTouchEfiVariables = true;
    boot.loader.systemd-boot.enable = bootloader.systemd.enable;
  };
}

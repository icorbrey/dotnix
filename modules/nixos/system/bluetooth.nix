{ config, lib, ... }: {
  options.modules.nixos.system.bluetooth = {
    enable = lib.mkEnableOption "Bluetooth";
  };

  config = let bluetooth = config.modules.nixos.system.bluetooth;
    in lib.mkIf bluetooth.enable {
      hardware.bluetooth = {
        powerOnBoot = true;
        enable = true;
        settings = {
          General.FastConnectable = true;
          General.Experimental = true;
          Policy.AutoEnable = true;
        };
      };
    };
}

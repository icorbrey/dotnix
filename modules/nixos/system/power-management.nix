{ config, lib, ... }: {
  options.modules.nixos.system.power-management = {
    enable = lib.mkEnableOption "Power management";
  };

  config = let power-management = config.modules.nixos.system.power-management;
    in lib.mkIf power-management.enable {
      services.power-profiles-daemon.enable = true;
      services.upower.enable = true;
    };
}

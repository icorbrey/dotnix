{ config, lib, ... }: {
  options.modules.nixos.system.networking = {
    enable = lib.mkOption {
      default = true;
      type = lib.types.boolean;
    };
  };

  config = let inherit (config.modules.nixos.system) networking;
    in lib.mkIf networking.enable {
      networking.networkmanager.enable = true;
    };
}

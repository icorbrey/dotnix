{ config, lib, ... }: {
  options.modules.nixos.system.time = {
    timeZone = lib.mkOption {
      default = "America/Indiana/Indianapolis";
      type = lib.types.str;
    };
  };

  config = let time = config.modules.nixos.system.time;
    in {
      time.timeZone = time.timeZone;
    };
}

{ config, lib, ... }: {
  options.modules.nixos.kdeconnect = {
    enable = lib.mkEnableOption "KDE Connect";
  };

  config = let kdeconnect = config.modules.nixos.kdeconnect;
    in lib.mkIf kdeconnect.enable {
      programs.kdeconnect.enable = true;
    };
}

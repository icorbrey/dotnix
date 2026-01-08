{ config, lib, pkgs, ... }: {
  options.modules.home.steam = {
    enable = lib.mkEnableOption "steam";
  };

  config = lib.mkIf config.modules.home.steam.enable {
    home.packages = [
      pkgs.steam
    ];
  };
}

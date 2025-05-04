{ config, lib, pkgs, ... }: {
  options.modules.home.home-manager = {
    enable = lib.mkEnableOption "home-manager";
  };

  config = lib.mkIf config.modules.home.home-manager.enable {
    home.packages = [
      pkgs.home-manager
    ];
  };
}

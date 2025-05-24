{ config, lib, ... }: {
  options.modules.home.steam = {
    enable = lib.mkEnableOption "steam";
  };

  config.modules.home.flatpak.apps = {
    "com.valvesoftware.Steam".enable = config.modules.home.steam.enable;
  };
}

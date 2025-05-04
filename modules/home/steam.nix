{ config, lib, ... }: {
  options.modules.home.steam = {
    enable = lib.mkEnableOption "steam";
  };

  config = lib.mkIfEnabled config.modules.home.steam.enable {
    modules.home.flatpak.apps = [
      "com.valvesoftware.Steam"
    ];
  };
}

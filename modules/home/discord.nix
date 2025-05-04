{ config, lib, ... }: {
  options.modules.home.discord = {
    enable = lib.mkEnableOption "discord";
  };

  config = lib.mkIfEnabled config.modules.home.discord.enable {
    modules.home.flatpak.apps = [
      "com.discordapp.Discord"
    ];
  };
}

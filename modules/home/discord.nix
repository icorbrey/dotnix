{ config, lib, ... }: {
  options.modules.home.discord = {
    enable = lib.mkEnableOption "discord";
  };

  config.modules.home.flatpak.apps = {
    "com.discordapp.Discord".enable = config.modules.home.discord.enable;
  };
}

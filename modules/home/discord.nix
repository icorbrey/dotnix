{ config, lib, ... }: {
  options.modules.home.discord = {
    enable = lib.mkEnableOption "discord";
  };

  config = lib.mkIf config.modules.home.discord.enable {
    modules.home.flatpak.apps = [
      "com.discordapp.Discord"
    ];
  };
}

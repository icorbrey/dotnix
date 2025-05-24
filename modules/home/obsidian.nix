{ config, lib, ... }: {
  options.modules.home.obsidian = {
    enable = lib.mkEnableOption "obsidian";
  };

  config.modules.home.flatpak.apps = {
    "md.obsidian.Obsidian".enable = config.modules.home.obsidian.enable;
  };
}

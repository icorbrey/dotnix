{ config, lib, ... }: {
  options.modules.home.obsidian = {
    enable = lib.mkEnableOption "obsidian";
  };

  config = lib.mkIfEnabled config.modules.home.obsidian.enable {
    modules.home.flatpak.apps = [
      "md.obsidian.Obsidian"
    ];
  };
}

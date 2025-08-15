{ config, lib, ... }: {
  options.modules.home.wezterm = {
    enable = lib.mkEnableOption "wezterm";
  };

  config = let wezterm = config.modules.home.wezterm;
    in lib.mkIf wezterm.enable (lib.mkMerge [
      {
        programs.wezterm.enable = true;
        programs.wezterm.extraConfig = builtins.readFile ./wezterm.lua;
      }
    ]);
}

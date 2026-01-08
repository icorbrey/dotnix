{
  config,
  lib,
  ...
}: {
  options.modules.home.wezterm = {
    enable = lib.mkEnableOption "wezterm";
  };

  config = let
    wezterm = config.modules.home.wezterm;
  in
    lib.mkIf wezterm.enable (lib.mkMerge [
      {
        modules.home.wsl-bridge.map = {
          "~/.config/wezterm/wezterm.lua" = {
            directory = {userHome, ...}: userHome;
            filename = ".wezterm.lua";
          };
        };

        programs.wezterm.enable = true;
        programs.wezterm.extraConfig = builtins.readFile ./wezterm.lua;
      }
    ]);
}

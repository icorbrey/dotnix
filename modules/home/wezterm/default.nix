{
  config,
  lib,
  ...
}: {
  options.modules.home.wezterm = {
    enable = lib.mkEnableOption "wezterm";

    install = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to install the WezTerm application via Nix.";
    };
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
      }
      (lib.mkIf wezterm.install {
        programs.wezterm = {
          enable = true;
          extraConfig = builtins.readFile ./wezterm.lua;
        };
      })
      (lib.mkIf (!wezterm.install) {
        xdg.configFile."wezterm/wezterm.lua".source = ./wezterm.lua;
      })
    ]);
}

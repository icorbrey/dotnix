{ config, lib, pkgs, utils, ... }: {
  options.modules.home.cli-common = {
    enable = lib.mkEnableOption "cli-common";

    bat = utils.mkToggle "bat" true;
    eza = utils.mkToggle "eza" true;
    just = utils.mkToggle "just" true;
  };

  config = let cli-common = config.modules.home.cli-common;
    in lib.mkIf cli-common.enable {
      programs = {
        bat.enable = cli-common.bat.enable;
        eza.enable = cli-common.eza.enable;
      };

      home.packages = utils.mkIfOptions cli-common {
        just = pkgs.just;
      };

      modules.home.global.shellAliases = lib.mkMerge [
        (lib.mkIf cli-common.bat.enable {
          cat = "bat";
        })
        (lib.mkIf cli-common.eza.enable {
          ls = "eza --icons";
          ll = "eza -l --icons";
          la = "eza -a --icons";
          t = "eza --tree --group-directories-last --icons";
          tree = "eza --tree --group-directories-last --icons";
        })
      ];
    };
}

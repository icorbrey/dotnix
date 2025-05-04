{ config, lib, pkgs, utils, ... }: {
  options.modules.home.cli-common = {
    enable = lib.mkEnableOption "cli-common";

    bat = utils.mkToggle "bat" true;
    eza = utils.mkToggle "eza" true;
    just = utils.mkToggle "just" true;
  };

  config = let cli-common = config.modules.home.cli-common;
    in lib.mkIfEnabled cli-common.enable {
      programs = {
        bat.enable = cli-common.bat.enable;
        eza.enable = cli-common.eza.enable;
      }

      home.packages = utils.mkIfOptions cli-common {
        just = pkgs.just;
      };

      custom.shellAliases = {
        # Bat aliases
        cat = "bat";

        # Eza aliases
        ls = "eza";
        ll = "eza -l";
        la = "eza -a";
        t = "eza --tree --group-directories-last";
        tree = "eza --tree --group-directories-last";
      };
    };
}

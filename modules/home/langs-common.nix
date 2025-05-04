{ config, lib, pkgs, utils, ... }: {
  options.modules.home.langs-common = {
    enable = lib.mkEnableOption "langs-common";

    markdown = utils.mkToggle "markdown" true;
    nix = utils.mkToggle "nix" true;
    toml = utils.mkToggle "toml" true;
    yaml = utils.mkToggle "yaml" true;
  };

  config = let langs-common = config.modules.home.langs-common;
    in lib.mkIf langs-common.enable {
      home.packages = utils.mkIfOptions langs-common {
        markdown = [
          pkgs.markdown-oxide
          pkgs.marksman
        ];

        nix = pkgs.nil;
        toml = pkgs.taplo;
        yaml = pkgs.yaml-language-server;
      };
    };
}

{ config, lib, pkgs, utils, ... }: {
  options.modules.home.docker = {
    enable = lib.mkEnableOption "docker";

    k9s = utils.mkToggle "k9s" true;
  };

  config = let docker = config.modules.home.docker;
    in lib.mkIf docker.enable {
      home.packages =
        (utils.mkIfOptions docker {
          k9s = pkgs.k9s;
        }) ++ [
          pkgs.docker-compose-language-service
          pkgs.dockerfile-language-server-nodejs
        ];
    };
}

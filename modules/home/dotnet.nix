{ config, lib, pkgs, utils, ... }: {
  options.modules.home.dotnet = {
    enable = lib.mkEnableOption "dotnet";

    omnisharp = utils.mkToggle "omnisharp" true;
  };

  config = let dotnet = config.modules.home.dotnet;
    in lib.mkIf dotnet.enable {
      home.packages = utils.mkIfOptions dotnet {
        omnisharp = pkgs.omnisharp-roslyn;
      };
    };
}

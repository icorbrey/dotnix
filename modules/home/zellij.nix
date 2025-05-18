{ config, lib, pkgs, ... }: {
  options.modules.home.zellij = {
    enable = lib.mkEnableOption "zellij";
  };

  config = let zellij = config.modules.home.zellij;
    in lib.mkIf zellij.enable {
      home.packages = [
        pkgs.zellij
      ];

      modules.home.global.shellAliases = {
        z = "zellij";
        za = "zellij attach";
        zls = "zellij list-sessions";
      };
    };
}

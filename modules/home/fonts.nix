{ config, lib, pkgs, utils, ... }: {
  options.modules.home.fonts = {
    enable = lib.mkEnableOption "fonts";

    fira-code = utils.mkToggle "Fira Code" true;
  };

  config = let fonts = config.modules.home.fonts;
    in lib.mkIf fonts.enable {
      home.packages = utils.mkIfOptions fonts {
        fira-code = pkgs.fira-code;
      };
    };
}

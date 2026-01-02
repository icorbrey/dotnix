{ config, lib, pkgs, utils, ... }: {
  options.modules.home.fonts = {
    enable = lib.mkEnableOption "fonts";

    fira-code = utils.mkToggle "Fira Code" true;
    recursive = utils.mkToggle "Recursive" true;
  };

  config = let fonts = config.modules.home.fonts;
    in lib.mkIf fonts.enable {
      fonts.fontconfig.enable = true;
      
      home.packages = utils.mkIfOptions fonts {
        fira-code = pkgs.fira-code;
        recursive = [
          pkgs.recursive
          pkgs.nerd-fonts.recursive-mono
        ];
      };
    };
}

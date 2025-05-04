{ config, lib, ... }: {
  options.modules.home.helix = {
    enable = lib.mkEnableOption "helix";

    theme = lib.mkOption {
      type = lib.types.str;
      default = "darcula-solid";
    };
  };

  config = let helix = options.modules.home.helix;
    in lib.mkIfEnabled helix.enable {
      programs.helix = {
        enable = true;

        settings = {
          theme = helix.theme;

          editor = {
            line-number = "relative";
            true-color = true;

            file-picker.hidden = false;
            smart-tab.enable = false;
          }
        };

        languages = {
          language = [{
            name = "sql";
            soft-tabs = false;
            tab-width = 4;
          }];
        };
      };
    };
}

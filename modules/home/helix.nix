{ config, lib, ... }: {
  options.modules.home.helix = {
    enable = lib.mkEnableOption "helix";

    theme = lib.mkOption {
      type = lib.types.str;
      default = "darcula-solid";
    };
  };

  config = let helix = config.modules.home.helix;
    in lib.mkIf helix.enable {
      programs.helix = {
        enable = true;

        settings = {
          theme = helix.theme;

          editor = {
            line-number = "relative";
            bufferline = "always";
            true-color = true;

            file-picker.hidden = false;
            smart-tab.enable = false;
          };

          keys.normal = {
            # Emulate VSCode Ctrl+D functionality
            C-d = "@*vn<esc>";
            C-D = "@*vN<esc>";

            # Emulate VSCode Ctrl+Alt+Up/Down functionality
            C-A-up = "@v<A-C><esc>";
            C-A-k = "@v<A-C><esc>";
            C-A-down = "@vC<esc>";
            C-A-j = "@vC<esc>";

            # Navigate buffers
            A-pageup = ":bp";
            A-pagedown = ":bn";
          };

          keys.select = {
            # Emulate VSCode Ctrl+D functionality
            C-d = "@*n";
            C-D = "@*N";

            # Emulate VSCode Ctrl+Alt+Up/Down functionality
            C-A-up = "@<A-C>";
            C-A-k = "@<A-C>";
            C-A-down = "@C";
            C-A-j = "@C";

            # Navigate buffers
            A-pageup = "@<esc>:bp";
            A-pagedown = "@<esc>:bn";
          };

          keys.insert = {
            # Emulate VSCode Ctrl+D functionality
            C-d = "@<esc>*vn<esc>";
            C-D = "@<esc>*vN<esc>";

            # Emulate VSCode Ctrl+Alt+Up/Down functionality
            C-A-up = "@<esc>v<A-C>i";
            C-A-k = "@<esc>v<A-C>i";
            C-A-down = "@<esc>vCi";
            C-A-j = "@<esc>vCi";

            # Navigate buffers
            A-pageup = "@<esc>:bp";
            A-pagedown = "@<esc>:bn";
          };
        };

        languages = {
          language = [{
            name = "sql";
            indent.tab-width = 4;
            indent.unit = "    ";
          }];
        };
      };
    };
}

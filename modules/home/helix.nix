{ config, lib, pkgs, ... }: {
  options.modules.home.helix = {
    enable = lib.mkEnableOption "helix";

    theme = lib.mkOption {
      type = lib.types.str;
      default = "darcula-solid";
    };
  };

  config = let helix = config.modules.home.helix;
    in lib.mkIf helix.enable {
      modules.home.wsl-bridge.map = {
        "~/.config/helix/languages.toml" = {
          directory = { appData, ... }: "${appData}/helix";
          filename = "languages.toml";
        };
        "~/.config/helix/config.toml" = {
          directory = { appData, ... }: "${appData}/helix";
          filename = "config.toml";
        };
      };

      home.packages = [
        pkgs.steel
      ];
      
      programs.helix = {
        enable = true;

        settings = {
          theme = helix.theme;

          editor = {
            line-number = "relative";
            bufferline = "always";
            true-color = true;

            jump-label-alphabet = "jklfdsauiohnmretcgwvpyqxbz";

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

            # Move lines
            C-j = "@Xdp";
            C-k = "@XdkP";

            # Navigate buffers
            C-h = ":bp";
            C-l = ":bn";

            # Close buffer
            C-w = ":bc";

            # Close pane
            C-q = ":q";

            # Find word references
            F12 = "@miw*;<space>/<ret>";
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

            # Move lines
            C-j = "@<esc>Xdp";
            C-k = "@<esc>XdkP";

            # Navigate buffers
            C-q = "@<esc>:bc";
            C-h = "@<esc>:bp";
            C-l = "@<esc>:bn";

            # Find word references
            F12 = "@miw*;<space>/<ret>";
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
            C-q = "@<esc>:bc";
            C-h = "@<esc>:bp";
            C-l = "@<esc>:bn";

            # Find word references
            F12 = "@<esc>miw*;<space>/<ret>";
          };
        };

        languages = {
          language-server.emmet-language-server = {
            command = "emmet-language-server";
            args = ["--stdio"];
          };
          
          language-server.vscode-css-language-server = {
            command = "vscode-css-language-server";
            args = ["--stdio"];
          };
          
          language = let
            def = name: obj: { inherit name; } // obj;
          in [
            (def "git-commit" {
              rulers = [73];
            })
            (def "jjdescription" {
              rulers = [73];
            })
            (def "less" {
              scope = "source.less";
              file-types = ["less"];
              language-id = "less";
              grammar = "less";

              comment-tokens = ["//"];
              block-comment-tokens = [{
                start = "/*";
                end = "*/";
              }];

              indent.tab-width = 2;
              indent.unit = "  ";

              language-servers = [
                "vscode-css-language-server"
                "emmet-language-server"
              ];
            })
            (def "html" {
              language-servers = [
                "vscode-html-language-server"
                "emmet-language-server"
              ];
            })
            (def "jsx" {
              language-servers = [
                "typescript-language-server"
                "emmet-language-server"
              ];
            })
            (def "markdown" {
              rulers = [81];
            })
            (def "sql" {
              indent.tab-width = 4;
              indent.unit = "    ";
            })
            (def "tsx" {
              language-servers = [
                "typescript-language-server"
                "emmet-language-server"
              ];
            })
          ];

          grammar = [{
            name = "less";
            source.git = "https://github.com/jimliang/tree-sitter-less";
            source.rev = "945f52c94250309073a96bbfbc5bcd57ff2bde49";
          }];
        };
      };
    };
}

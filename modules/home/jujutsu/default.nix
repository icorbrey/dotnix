{ config, lib, ... }: {
  options.modules.home.jujutsu = {
    enable = lib.mkEnableOption "jujutsu";

    settings.tfvc = {
      enable = lib.mkEnableOption "tfvc support";
      url = lib.mkOption {
        type = with lib.types; str;
      };
    };

    settings.scopes = lib.mkOption {
      type = with lib.types; listOf attrs;
      default = [];
      example = [
        {
          "--when".repositories = ["~/oss"];
          user.email = "YOUR_OSS_EMAIL@example.org";
        }
        {
          "--when".commands = ["status"];
          ui.paginate = "never";
        }
        {
          "--when".commands = ["diff" "show"];
          ui.pager = "delta";
        }
      ];
    };
  };

  config = let jujutsu = config.modules.home.jujutsu;
    in lib.mkIf jujutsu.enable (lib.mkMerge [
      {
        modules.home.wsl-bridge.map = {
          "~/.config/jj/config.toml" = {
            directory = { appData, ... }: "${appData}/jj";
            filename = "config.toml";
          };
        };
    
        programs.git.enable = true;

        programs.jujutsu.enable = true;
        programs.jujutsu.settings = lib.mkMerge [
          {
            user.name = "Isaac Corbrey";
            user.email = "icorbrey@gmail.com";

            ui.default-command = "log";
            ui.editor = "hx";

            git.write-change-id-header = true;

            revset-aliases = {
              "closest_bookmark(to)" = "heads(::to & bookmarks())";
              "closest_pushable(to)" = "heads(::to & ~description(exact:'') & (~empty() | merges()))";
            };

            aliases.tug = ["bookmark" "move" "--from" "closest_bookmark(@)" "--to" "closest_pushable(@)"];
        
            template-aliases = {
              "format_short_signature(signature)" = "coalesce(signature.name(), coalesce(signature.email(), email_placeholder))";
              "format_timestamp(timestamp)" = "timestamp.ago()";
            };

            jjj.splash.skip = true;
          }
          (lib.mkIf (jujutsu.settings.scopes != []) {
            "--scope" = jujutsu.settings.scopes;
          })
        ];
      }
      (lib.mkIf config.modules.home.nushell.enable (lib.mkMerge [
        {
          modules.home.wsl-bridge.map = {
            "~/.config/jj/scripts/changelog.nu" = {
              directory = { userHome, ... }: "${userHome}/.config/jj/scripts";
              filename = "changelog.nu";
            };
            "~/.config/jj/scripts/review.nu" = {
              directory = { userHome, ... }: "${userHome}/.config/jj/scripts";
              filename = "review.nu";
            };
          };
        
          programs.jujutsu.settings = {
            aliases.changelog = ["util" "exec" "nu" "~/.config/jj/scripts/changelog.nu"];
            aliases.review = ["util" "exec" "nu" "~/.config/jj/scripts/review.nu"];
          };

          home.file.".config/jj/scripts/changelog.nu".source = ./changelog.nu;
          home.file.".config/jj/scripts/review.nu".source = ./review.nu;
        }
        (lib.mkIf jujutsu.settings.tfvc.enable {
          modules.home.wsl-bridge.map = {
            "~/.config/jj/scripts/tfvc.nu" = {
              directory = { userHome, ... }: "${userHome}/.config/jj/scripts";
              filename = "tfvc.nu";
            };
          };

          programs.jujutsu.settings = {
            aliases.tfvc = ["util" "exec" "nu" "~/.config/jj/scripts/tfvc.nu"];
          };

          home.file.".config/jj/scripts/tfvc.nu".source = ./tfvc.nu;
        })
      ]))
    ]);
}

{ config, lib, pkgs, ... }: {
  options.modules.home.jujutsu = {
    enable = lib.mkEnableOption "jujutsu";

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

    settings.signing = {
      enable = lib.mkOption {
        type = with lib.types; bool;
        default = true;
      };

      key = lib.mkOption {
        type = with lib.types; str;
      };
    };
    
    settings.tfvc = {
      enable = lib.mkEnableOption "tfvc support";
      url = lib.mkOption {
        type = with lib.types; str;
      };
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
    
        programs.mergiraf.enable = true;
        programs.jujutsu.enable = true;
        programs.git.enable = true;

        home.packages = [
          pkgs.difftastic
        ];

        programs.jujutsu.settings = lib.mkMerge [
          {
            user.name = "Isaac Corbrey";
            user.email = "isaac@isaaccorbrey.com";

            ui.diff-formatter = "difft";
            ui.default-command = "log";
            ui.editor = "hx";

            git.write-change-id-header = true;

            revset-aliases = {
              # Identity
              "user(x)" = "author(x) | committer(x)";
              "mine()" = let
                aliases = [
                  # Personal aliases
                  "isaac@isaaccorbrey.com"
                  "icorbrey@gmail.com"

                  # Do it Best aliases
                  "icorbrey@ntserv.doitbestcorp.com"
                  "isaac.corbrey@doitbest.com"

                  # University of Saint Francis aliases
                  "icorbrey@sf.edu"

                  # Historical aliases
                  "ICCorbrey01@indianatech.edu"
                  "isaac.corbrey@corebts.com"
                  "icorbrey@apterainc.com"
                ];
              in builtins.concatStringsSep " | " (builtins.map (x: "user('${x})'") aliases);

              # Tug helpers
              "closest_bookmark(to)" = "heads(::to & bookmarks())";
              "closest_pushable(to)" = "heads(::to & ~description(exact:'') & (~empty() | merges()))";

              # Megamerge helpers
              "mutable_roots()" = "roots(trunk()..) & mutable()";
              "closest_merge(to)" = "heads(::to & merges())";
            };

            aliases.jj = [];
            aliases.tug = ["bookmark" "move" "--from" "closest_bookmark(@)" "--to" "closest_pushable(@)"];
            aliases.restack = ["rebase" "-d" "trunk()" "-s" "mutable_roots()"];
            aliases.stack = ["rebase" "-A" "trunk()" "-B" "closest_merge(@)" "-r"];
            aliases.stage = ["stack" "closest_merge(@)+:: ~ empty()"];
            aliases.solve = ["resolve" "--tool" "mergiraf"];

            templates.git_push_bookmark = "git_push_bookmark";
        
            template-aliases = {
              "git_push_bookmark" = "'icorbrey/push-' ++ change_id.shortest(12)";
              "tfvc_push_bookmark" = "'push-' ++ change_id.shortest(12)";
              "format_short_signature(signature)" = "coalesce(signature.name(), coalesce(signature.email(), email_placeholder))";
              "format_timestamp(timestamp)" = "timestamp.ago()";
            };

            jjj.splash.skip = true;

            merge-tools.difft = {
              program = "difft";
              diff-args = ["--color=always" "$left" "$right"];
              diff-invocation-mode = "file-by-file";
            };
          }
          (lib.mkIf jujutsu.settings.signing.enable {
            git.sign-on-push = true;

            signing.key = jujutsu.settings.signing.key;
            signing.behavior = "drop";
            signing.backend = "ssh";
          })
          (lib.mkIf (jujutsu.settings.scopes != []) {
            "--scope" = jujutsu.settings.scopes;
          })
        ];
      }
      (lib.mkIf (config.modules.home.nushell.enable && jujutsu.settings.tfvc.enable) {
        modules.home.wsl-bridge.map = {
          "~/.config/jj/scripts/tfvc.nu" = {
            directory = { userHome, ... }: "${userHome}/.config/jj/scripts";
            filename = "tfvc.nu";
          };
        };

        programs.jujutsu.settings = {
          aliases.tfvc = ["util" "exec" "nu" "~/.config/jj/scripts/tfvc.nu"];
          tfvc.url = jujutsu.settings.tfvc.url;
        };

        home.file.".config/jj/scripts/tfvc.nu".source = ./tfvc.nu;
      })
    ]);
}

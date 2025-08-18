{ config, lib, ... }: {
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
              "immutable_heads()" = "builtin_immutable_heads() | (trunk().. & ~mine()) ~ bookmarks(glob:'review/*@origin')";
              "closest_bookmark(to)" = "heads(::to & bookmarks())";
              "closest_pushable(to)" = "heads(::to & ~description(exact:'') & (~empty() | merges()))";
              "closest_merge(to)" = "heads(::to & merges())";
            };

            aliases.jj = [];
            aliases.tug = ["bookmark" "move" "--from" "closest_bookmark(@)" "--to" "closest_pushable(@)"];
            aliases.stack = ["rebase" "-A" "trunk()" "-B" "closest_merge(@)" "-r"];

            templates.git_push_bookmark = "'icorbrey/push-' ++ change_id.shortest(12)";
        
            template-aliases = {
              "format_short_signature(signature)" = "coalesce(signature.name(), coalesce(signature.email(), email_placeholder))";
              "format_timestamp(timestamp)" = "timestamp.ago()";
              "format_short_commit_header(commit)" = ''
                separate(" ",
                  format_short_change_id_with_hidden_and_divergent_info(commit),
                  format_short_signature(commit.author()),
                  format_timestamp(commit_timestamp(commit)),
                  commit.bookmarks().filter(|b| !b.name().starts_with("review/")),
                  commit.tags(),
                  commit.working_copies(),
                  if(commit.git_head(), label("git_head", "git_head()")),
                  format_short_commit_id(commit.commit_id()),
                  if(commit.conflict(), label("conflict", "conflict")),
                  if(config("ui.show-cryptographic-signatures").as_boolean(),
                    format_short_cryptographic_signature(commit.signature())),
                )
              '';
              "prompt" = "
                'at ' ++ concat(
                  label(
                    separate(' ',
                      if(current_working_copy, 'working_copy'),
                      if(immutable, 'immutable'),
                      if(conflict, 'conflict'),
                      if(divergent, 'divergent'),
                      if(hidden, 'hidden'),
                    ),
                    if(divergent, '?? ', if(conflict, '× ', '')),
                  ),
                  change_id.shortest(8),
                  ' ',
                  if(empty,
                    label('empty',
                      concat(
                        '(∅',
                        if(!description, ',Đ'),
                        ')',
                      ),
                    ),
                  ),
                  if(description,
                    truncate_end(32, description.first_line(), '…'),
                    label('description placeholder', if(!empty, '(Đ)')),
                  ),
                ) ++ ' '
              ";
            };

            jjj.splash.skip = true;

            review.wip-prefix = "wip/";
            review.review-prefix = "review/";
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
            tfvc.url = jujutsu.settings.tfvc.url;
          };

          home.file.".config/jj/scripts/tfvc.nu".source = ./tfvc.nu;
        })
      ]))
    ]);
}

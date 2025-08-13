{ config, lib, ... }: {
  options.modules.home.starship = {
    enable = lib.mkEnableOption "starship";
  };

  config = let starship = config.modules.home.starship;
    in lib.mkIf starship.enable {
      programs.starship.enable = true;
      programs.starship.settings = {
        cmd_duration.disabled = true;
        directory.style = "bold blue";

        git_branch.disabled = true;
        git_commit.disabled = true;
        git_status.disabled = true;

        custom.jj = {
          ignore_timeout = true;
          description = "The current jj status";
          when = true;
          command = "jj log -r @ --no-graph --color always -T prompt --ignore-working-copy && jj op log -T 'id.short(8)' --limit 1 --no-graph --color always --ignore-working-copy";
          style = "none";
        };
        
        username.show_always = true;
      };
    };
}

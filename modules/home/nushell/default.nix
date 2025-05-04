{ config, lib, ... }: {
  options.modules.home.nushell = {
    enable = lib.mkEnableOption "nushell";
  };

  config = let nushell = config.modules.home.nushell;
    in lib.mkIf nushell.enable (lib.mkMerge [
      {
        programs.nushell.enable = true;
        programs.nushell.extraConfig = ''
          $env.config.show_banner = false;

          $env.PATH = $env.PATH
            | split row (char esep)
            | prepend /home/icorbrey/.apps
            | append /usr/bin/env

          $env.EDITOR = "${config.modules.home.global.editor}"
        '';

        programs.nushell.shellAliases = lib.mkMerge [
          config.modules.home.global.shellAliases
          {
            clear = "clear -k";
          }
        ];
      }
      (lib.mkIf (config.modules.home.global.shell == "nu") {
        programs.bash.enable = true;
        programs.bash.initExtra = ''
          if [ -z "$NUSHELL_ACTIVE" ] && [ -t 1 ]; then
            export NUSHELL_ACTIVE=1
            exec ${config.programs.nushell.package}/bin/nu
          fi
        '';
      })
      (lib.mkIf config.modules.home.jujutsu.enable {
        home.file.".config/jj/scripts/changelog.nu".source = ./changelog.nu;
      })
    ]);
}

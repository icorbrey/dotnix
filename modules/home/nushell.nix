{
  config,
  lib,
  ...
}: {
  options.modules.home.nushell = {
    enable = lib.mkEnableOption "nushell";
  };

  config = let
    nushell = config.modules.home.nushell;
  in
    lib.mkIf nushell.enable (lib.mkMerge [
      {
        programs.nushell.enable = true;
        programs.nushell.extraConfig = ''
          $env.config.show_banner = false;

          $env.PATH = $env.PATH
            | split row (char esep)
            | prepend /home/icorbrey/.apps
            | append /usr/bin/env

          $env.EDITOR = "${config.modules.home.global.editor}"

          # Prevent scroll-on-type bug: https://github.com/nushell/nushell/issues/5585
          let isWsl = (sys host | get kernel_version) =~ '(microsoft-)\S+(-WSL)\S+$'
          $env.config.shell_integration.osc133 = (not $isWsl)
        '';

        programs.nushell.shellAliases = lib.mkMerge [
          config.modules.home.global.shellAliases
          {
            # Don't get rid of command outputs
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
    ]);
}

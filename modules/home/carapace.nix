{ config, lib, ... }: {
  options.modules.home.carapace = {
    enable = lib.mkEnableOption "carapace";
  };

  config = let carapace = config.modules.home.carapace;
    in lib.mkIf carapace.enable (lib.mkMerge [
      {
        programs.carapace.enable = true;
      }
      (lib.mkIf config.modules.home.nushell.enable {
        programs.carapace.enableNushellIntegration = true;

        programs.nushell.extraConfig = ''
          let carapace_completer = {|spans|
            carapace $spans.0 nushell ...$spans | from json
          }

          $env.config.completions = {
            case_sensitive: false
            algorithm: "fuzzy"
            partial: true
            quick: true

            external: {
              completer: $carapace_completer
              max_results: 100
              enable: true
            }
          }
        '';
      })
    ]);
}

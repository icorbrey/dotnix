{ config, lib, utils, ... }: {
  options.modules.home.nushell = {
    enable = lib.mkEnableOption "nushell";
  };

  config = let nushell = config.modules.home.nushell;
    in lib.mkIfEnabled nushell.enable {
      programs.nushell.enable = true;
      programs.nushell.extraConfig = ''
        $env.config.show_banner = false;

        $env.PATH = $env.PATH
          | split row (char esep)
          | prepend /home/icorbrey/.apps
          | append /usr/bin/env
      '';

      home.file = lib.mkIfEnabled config.modules.home.jujutsu.enable {
        ".config/jj/scripts/changelog.nu".source = ./changelog.nu;
      };
    };
}

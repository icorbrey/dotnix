{ config, lib, ... }: {
  options.modules.home.starship = {
    enable = lib.mkEnableOption "starship";
  };

  config = let starship = config.modules.home.starship;
    in lib.mkIf starship.enable {
      programs.starship.enable = true;
      programs.starship.settings = {
        directory.style = "bold blue";
        cmd_duration.disabled = true;
        username.show_always = true;
      };
    };
}

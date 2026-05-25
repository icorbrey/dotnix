{
  config,
  lib,
  pkgs,
  ...
}: {
  options.modules.home.teams = {
    enable = lib.mkEnableOption "teams-for-linux";
  };

  config = lib.mkIf config.modules.home.teams.enable {
    home.packages = [
      pkgs.teams-for-linux
    ];
  };
}

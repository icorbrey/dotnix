{
  config,
  lib,
  pkgs,
  ...
}: {
  options.modules.home.vlc = {
    enable = lib.mkEnableOption "vlc";
  };

  config = lib.mkIf config.modules.home.vlc.enable {
    home.packages = [
      pkgs.vlc
    ];
  };
}

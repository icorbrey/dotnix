{
  config,
  lib,
  ...
}: {
  options.modules.home.dank-material-shell = {
    enable = lib.mkEnableOption "DankMaterialShell";
  };

  config = let
    dms = config.modules.home.dank-material-shell;
  in
    lib.mkIf dms.enable {
      programs.dank-material-shell = {
        enable = true;
        systemd.enable = false;
      };
    };
}

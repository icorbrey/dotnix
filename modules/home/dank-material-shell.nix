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
    niri = config.modules.home.niri.enable;
  in
    lib.mkIf dms.enable {
      programs.dank-material-shell = {
        enable = true;
        systemd.enable = true;
      };

      systemd.user.services.dms = lib.mkIf niri {
        Unit.ConditionEnvironment = [
          "XDG_CURRENT_DESKTOP=niri"
          "XDG_SESSION_DESKTOP=niri"
          "DESKTOP_SESSION=niri"
        ];
      };
    };
}

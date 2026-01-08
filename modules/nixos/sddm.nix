{
  config,
  lib,
  ...
}: {
  options.modules.nixos.sddm = {
    enable = lib.mkEnableOption "sddm";

    defaultSession = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Optional default session for SDDM (e.g. \"niri\").";
    };
  };

  config = let
    sddm = config.modules.nixos.sddm;
  in
    lib.mkIf sddm.enable (lib.mkMerge [
      {
        services.displayManager.sddm.enable = true;
      }
      (lib.mkIf (sddm.defaultSession != null) {
        services.displayManager.defaultSession = sddm.defaultSession;
      })
    ]);
}

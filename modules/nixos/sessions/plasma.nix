{
  config,
  lib,
  ...
}: {
  options.modules.nixos.sessions.plasma = {
    enable = lib.mkEnableOption "plasma";
  };

  config = let
    plasma = config.modules.nixos.sessions.plasma;
  in
    lib.mkIf plasma.enable {
      services.desktopManager.plasma6.enable = true;
    };
}

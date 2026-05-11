{
  config,
  lib,
  ...
}: {
  options.modules.nixos.traefik = {
    enable = lib.mkEnableOption "traefik";
  };

  config = let
    traefik = config.modules.nixos.traefik;
  in
    lib.mkIf traefik.enable {
      services.traefik.enable = true;
    };
}

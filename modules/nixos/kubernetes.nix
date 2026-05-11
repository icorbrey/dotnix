{
  config,
  lib,
  ...
}: {
  options.modules.nixos.kubernetes = {
    enable = lib.mkEnableOption "kubernetes";
  };

  config = let
    kubernetes = config.modules.nixos.kubernetes;
    traefik = config.modules.nixos.traefik;
    backups = config.modules.nixos.backups;
  in
    lib.mkIf kubernetes.enable (lib.mkMerge [
      {
        services.k3s.enable = true;
        services.k3s.extraFlags = lib.mkIf traefik.enable "--disable traefik";
      }
      (lib.mkIf backups.enable {
        modules.nixos.backups.paths = ["/var/lib/rancher/k3s/server/token"];
      })
    ]);
}

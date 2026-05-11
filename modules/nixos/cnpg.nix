{
  config,
  lib,
  pkgs,
  ...
}: {
  options.modules.nixos.cnpg = {
    enable = lib.mkEnableOption "CloudNativePG operator";
  };

  config = let
    cnpg = config.modules.nixos.cnpg;
  in
    lib.mkIf cnpg.enable {
      assertions = [
        {
          assertion = config.modules.nixos.kubernetes.enable;
          message = "modules.nixos.kubernetes must be enabled to use CloudNativePG";
        }
      ];

      systemd.tmpfiles.rules = let
        helmChart = pkgs.writeText "cnpg-helmchart.yaml" ''
          apiVersion: v1
          kind: Namespace
          metadata:
            name: cnpg-system
          ---
          apiVersion: helm.cattle.io/v1
          kind: HelmChart
          metadata:
            name: cloudnative-pg
            namespace: kube-system
          spec:
            repo: https://cloudnative-pg.github.io/charts
            chart: cloudnative-pg
            targetNamespace: cnpg-system
        '';
      in [
        "L /var/lib/rancher/k3s/server/manifests/cnpg.yaml - - - - ${helmChart}"
      ];
    };
}

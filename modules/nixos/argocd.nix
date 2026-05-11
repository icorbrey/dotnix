{
  config,
  lib,
  pkgs,
  ...
}: {
  options.modules.nixos.argocd = {
    enable = lib.mkEnableOption "argocd";

    hostname = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Hostname for the ArgoCD web UI (required when Traefik is enabled)";
    };
  };

  config = let
    argocd = config.modules.nixos.argocd;
    kubernetes = config.modules.nixos.kubernetes;
    traefik = config.modules.nixos.traefik;

    helmChart = pkgs.writeText "argocd-helmchart.yaml" (''
      apiVersion: v1
      kind: Namespace
      metadata:
        name: argocd
      ---
      apiVersion: helm.cattle.io/v1
      kind: HelmChart
      metadata:
        name: argocd
        namespace: kube-system
      spec:
        repo: https://argoproj.github.io/argo-helm
        chart: argo-cd
        targetNamespace: argocd
    '' + lib.optionalString traefik.enable ''
        valuesContent: |-
          server:
            extraArgs:
              - --insecure
    '');
  in
    lib.mkIf argocd.enable (lib.mkMerge [
      {
        assertions = [
          {
            assertion = kubernetes.enable;
            message = "modules.nixos.kubernetes must be enabled to use ArgoCD";
          }
          {
            assertion = !traefik.enable || argocd.hostname != null;
            message = "modules.nixos.argocd.hostname must be set when Traefik is enabled";
          }
        ];

        systemd.tmpfiles.rules = [
          "L /var/lib/rancher/k3s/server/manifests/argocd.yaml - - - - ${helmChart}"
        ];
      }
      (lib.mkIf (traefik.enable && argocd.hostname != null) (let
        ingressRoute = pkgs.writeText "argocd-ingressroute.yaml" ''
          apiVersion: traefik.io/v1alpha1
          kind: IngressRoute
          metadata:
            name: argocd-server
            namespace: argocd
          spec:
            entryPoints:
              - web
              - websecure
            routes:
              - match: Host(`${argocd.hostname}`)
                kind: Rule
                services:
                  - name: argocd-server
                    port: 80
        '';
      in {
        systemd.tmpfiles.rules = [
          "L /var/lib/rancher/k3s/server/manifests/argocd-ingressroute.yaml - - - - ${ingressRoute}"
        ];
      }))
    ]);
}

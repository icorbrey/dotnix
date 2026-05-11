{ ... }: {
  imports = [
    ../../modules/nixos
  ];

  networking.hostName = "lethe";
  system.stateVersion = "26.05";

  users.users.icorbrey = {
    isNormalUser = true;
    description = "Isaac Corbrey";
    extraGroups = ["networkmanager" "wheel"];
  };

  modules.nixos = {
    system.tailscale.enable = true;

    kubernetes.enable = true;
    backups.enable = true;
    spindle.enable = true;
    traefik.enable = true;
    argocd.enable = true;
    cnpg.enable = true;
    ddns.enable = true;
    knot.enable = true;

    global.did = "did:plc:zviscnpwyvj6y32agi5davn5";

    ddns.domains = ["lethe.observer"];

    spindle.hostname = "spindle.lethe.observer";
    argocd.hostname = "argo.lethe.observer";
    knot.hostname = "knot.lethe.observer";
  };
}

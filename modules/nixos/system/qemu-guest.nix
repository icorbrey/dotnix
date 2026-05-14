{
  config,
  lib,
  pkgs,
  ...
}: {
  options.modules.nixos.system.qemu-guest = {
    enable = lib.mkEnableOption "QEMU/SPICE guest integration (agent, clipboard, IPv4 DHCP timing)";
  };

  config = let
    qemu-guest = config.modules.nixos.system.qemu-guest;
  in
    lib.mkIf qemu-guest.enable {
      services.qemuGuest.enable = true;
      services.spice-vdagentd.enable = true;

      environment.systemPackages = [
        pkgs.spice-vdagent
      ];

      # QEMU SLIRP answers IPv6 SLAAC near-instantly but is slow on IPv4 DHCP;
      # NM's default `may-fail = yes` declares the link "up" once v6 lands and
      # silently drops the v4 lease attempt. Require v4 and give it room to land.
      networking.networkmanager.connectionConfig = {
        "ipv4.may-fail" = false;
        "ipv4.dhcp-timeout" = 90;
      };
    };
}

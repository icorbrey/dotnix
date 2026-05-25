{...}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos
  ];

  networking.hostName = "hestia";
  system.stateVersion = "25.11";

  users.users.icorbrey = {
    isNormalUser = true;
    description = "Isaac Corbrey";
    extraGroups = ["networkmanager" "wheel"];
  };

  modules.nixos = {
    system.parallels-guest.enable = true;
    system.tailscale.enable = true;
    system.wayland.enable = true;
    system.ssh.enable = true;

    sessions.plasma.enable = true;
    sessions.niri.enable = true;

    sddm.enable = true;
    sddm.defaultSession = "plasma";

    _1password.enable = true;
    kdeconnect.enable = true;
    firefox.enable = true;
  };
}

{...}: {
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos
  ];

  networking.hostName = "elysium";
  system.stateVersion = "25.11";

  users.users.icorbrey = {
    isNormalUser = true;
    description = "Isaac Corbrey";
    extraGroups = ["networkmanager" "wheel"];
  };

  modules.nixos = {
    system.networking.enable = true;
    system.bluetooth.enable = true;
    system.tailscale.enable = true;
    system.printing.enable = true;
    system.flatpak.enable = true;
    system.wayland.enable = true;
    system.nvidia.enable = true;

    sessions.plasma.enable = true;
    sessions.niri.enable = true;

    sddm.enable = true;
    sddm.defaultSession = "niri";

    _1password.enable = true;
    kdeconnect.enable = true;
    firefox.enable = true;
    keymapp.enable = true;
    zen.enable = true;

    docker.enable = true;
    docker.users = ["icorbrey"];
  };
}

{ ... }: {
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos
  ];

  networking.hostName = "zephyr";

  users.users.icorbrey = {
    isNormalUser = true;
    description = "Isaac Corbrey";
    extraGroups = ["networkmanager" "wheel"];
  };

  modules.nixos = {
    system.bluetooth.enable = true;
    system.printing.enable = true;
    system.flatpak.enable = true;
    
    sessions.plasma.enable = true;
    sessions.niri.enable = true;

    _1password.enable = true;
    kdeconnect.enable = true;
    firefox.enable = true;
    keymapp.enable = true;
  };
}

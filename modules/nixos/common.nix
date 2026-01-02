{ ... }: {
  nixpkgs.config.allowAliases = true;
  nixpkgs.config.allowUnfree = true;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  
  services.displayManager.sddm.enable = true;
}

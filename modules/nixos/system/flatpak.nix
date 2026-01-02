{ config, lib, ... }: {
  options.modules.nixos.system.flatpak = {
    enable = lib.mkEnableOption "Flatpak";
  };

  config = let flatpak = config.modules.nixos.system.flatpak;
    in lib.mkIf flatpak.enable {
      services.flatpak.enable = true;
    };
}

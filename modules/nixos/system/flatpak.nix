{
  config,
  lib,
  pkgs,
  ...
}: {
  options.modules.nixos.system.flatpak = {
    enable = lib.mkEnableOption "Flatpak";
  };

  config = let
    flatpak = config.modules.nixos.system.flatpak;
  in
    lib.mkIf flatpak.enable {
      services.flatpak.enable = true;
      environment.etc."flatpak/overrides/global".text = ''
        [Environment]
        TZ=${config.time.timeZone}
      '';
      environment.systemPackages = [
        pkgs.warehouse
      ];
    };
}

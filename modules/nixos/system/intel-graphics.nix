{
  config,
  lib,
  pkgs,
  ...
}: {
  options.modules.nixos.system.intel-graphics = {
    enable = lib.mkEnableOption "Intel graphics (VAAPI drivers/utilities)";
  };

  config = let
    intelGraphics = config.modules.nixos.system.intel-graphics;
  in
    lib.mkIf intelGraphics.enable {
      hardware.graphics.enable = true;
      hardware.graphics.extraPackages = with pkgs; [
        intel-media-driver
        intel-vaapi-driver
      ];
      environment.systemPackages = [
        pkgs.libva-utils
      ];
    };
}

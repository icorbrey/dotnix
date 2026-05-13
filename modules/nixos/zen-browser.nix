{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: {
  options.modules.nixos.zen = {
    enable = lib.mkEnableOption "Zen Browser";
  };

  config = let
    zen = config.modules.nixos.zen;
    zenPackage = inputs."zen-browser".packages.${pkgs.system}.default;
  in
    lib.mkIf zen.enable {
      environment.systemPackages = [
        zenPackage
      ];
    };
}

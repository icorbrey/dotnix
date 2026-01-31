{
  config,
  lib,
  pkgs,
  ...
}: {
  options.modules.nixos.system.tailscale = {
    enable = lib.mkEnableOption "tailscale (system daemon)";
  };

  config = let
    tailscale = config.modules.nixos.system.tailscale;
  in
    lib.mkIf tailscale.enable {
      services.tailscale.enable = true;
      environment.systemPackages = [
        pkgs.tailscale
      ];
    };
}

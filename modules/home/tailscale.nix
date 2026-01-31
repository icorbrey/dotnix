{
  config,
  lib,
  pkgs,
  ...
}: {
  options.modules.home.tailscale = {
    enable = lib.mkEnableOption "tailscale";
  };

  config = let
    tailscale = config.modules.home.tailscale;
  in
    lib.mkIf tailscale.enable {
      home.packages = [
        pkgs.tailscale
        pkgs.tailscale-systray
      ];
    };
}

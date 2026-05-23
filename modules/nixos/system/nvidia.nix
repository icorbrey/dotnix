{
  config,
  lib,
  ...
}: {
  options.modules.nixos.system.nvidia = {
    enable = lib.mkEnableOption "NVIDIA proprietary driver (Wayland-ready, 32-bit graphics)";
  };

  config = let
    nvidia = config.modules.nixos.system.nvidia;
  in
    lib.mkIf nvidia.enable {
      hardware.graphics.enable = true;
      hardware.graphics.enable32Bit = true;

      services.xserver.videoDrivers = ["nvidia"];

      hardware.nvidia = {
        modesetting.enable = true;
        package = config.boot.kernelPackages.nvidiaPackages.stable;
        open = false;
        nvidiaSettings = true;
        powerManagement.enable = false;
      };
    };
}

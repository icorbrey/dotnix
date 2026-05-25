{
  config,
  lib,
  ...
}: {
  options.modules.nixos.system.parallels-guest = {
    enable = lib.mkEnableOption "Parallels Desktop guest integration (Parallels Tools, shared folders, clipboard, dynamic resolution)";
  };

  config = lib.mkIf config.modules.nixos.system.parallels-guest.enable {
    # Enables prl-tools, kernel modules (prl_fs, prl_tg, prl_fs_freeze),
    # prltoolsd, and X server drivers (prlvideo/prlmouse).
    hardware.parallels.enable = true;
  };
}

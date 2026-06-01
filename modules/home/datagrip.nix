{
  config,
  lib,
  ...
}: {
  options.modules.home.datagrip = {
    enable = lib.mkEnableOption "datagrip";
  };

  config.modules.home.flatpak.apps = {
    "com.jetbrains.DataGrip".enable = config.modules.home.datagrip.enable;
  };
}

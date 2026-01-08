{
  config,
  lib,
  ...
}: {
  options.modules.nixos.firefox = {
    enable = lib.mkEnableOption "Firefox";
  };

  config = let
    firefox = config.modules.nixos.firefox;
  in
    lib.mkIf firefox.enable {
      programs.firefox.enable = true;
    };
}

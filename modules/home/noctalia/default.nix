{
  config,
  lib,
  ...
}: {
  options.modules.home.noctalia = {
    enable = lib.mkEnableOption "Noctalia shell";
  };

  config = let
    noctalia = config.modules.home.noctalia;
  in
    lib.mkIf noctalia.enable {
      xdg.configFile."noctalia/settings.json".source = ./settings.json;
    };
}

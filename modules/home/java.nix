{
  config,
  lib,
  pkgs,
  ...
}: {
  options.modules.home.java = {
    enable = lib.mkEnableOption "java";
  };

  config = let
    java = config.modules.home.java;
  in
    lib.mkIf java.enable {
      home.packages = [
        pkgs.jdt-language-server
      ];
    };
}

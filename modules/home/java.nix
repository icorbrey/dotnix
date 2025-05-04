{ config, lib, pkgs, ... }: {
  output.modules.home.java = {
    enable = lib.mkEnableOption "java";
  };

  config = let java = config.modules.home.java;
    in lib.mkIfEnabled java.enable {
      home.packages = [
        pkgs.jdt-language-server
      ];
    };
}

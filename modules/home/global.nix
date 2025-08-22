{ lib, ... }: {
  options.modules.home.global = {
    editor = lib.mkOption {
      type = with lib.types; str;
      default = "vi";
    };

    shell = lib.mkOption {
      type = with lib.types; str;
      default = "bash";
    };

    terminal = lib.mkOption {
      type = with lib.types; str;
      default = "xterm";
    };
    
    shellAliases = lib.mkOption {
      type = with lib.types; attrsOf str;
      default = {};
    };
  };
}

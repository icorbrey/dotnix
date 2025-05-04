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
    
    shellAliases = lib.mkOption {
      type = with lib.types; attrsOf str;
      default = {};
    };
  };
}

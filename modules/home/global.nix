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

    hostName = lib.mkOption {
      type = with lib.types; nullOr str;
      default = null;
      description = "Hostname for host-scoped config (e.g., Niri host fragments).";
    };
  };
}

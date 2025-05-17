{ config, lib, ... }: {
  options.modules.home.wsl-bridge = {
    enable = lib.mkEnableOption "WSL bridge";

    paths = lib.mkOption {
      type = with lib.types; attrsOf str;
      default = {};
    };

    map = lib.mkOption {
      type = with lib.types; attrsOf (functionTo str);
    };
  };

  config = let wsl-bridge = config.modules.home.wsl-bridge;
    in lib.mkIf wsl-bridge.enable {
      home.activation.wslBridge = lib.hm.dag.entryAfter ["writeBoundary"]
        (builtins.concatStringsSep "\n"
          (lib.mapAttrsToList
            (from: mapTo: "cp ${from} ${mapTo wsl-bridge.paths}")
            wsl-bridge.map));
    };
}

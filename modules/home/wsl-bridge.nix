{ config, lib, ... }: {
  options.modules.home.wsl-bridge = {
    enable = lib.mkEnableOption "WSL bridge";

    paths = lib.mkOption {
      type = with lib.types; attrsOf str;
      default = {};
    };

    map = lib.mkOption {
      type = with lib.types; attrsOf (submodule {
        options = {
          directory = lib.mkOption {
            type = functionTo str;
          };
          filename = lib.mkOption {
            type = str;
          };
        };
      });
    };
  };

  config = let wsl-bridge = config.modules.home.wsl-bridge;
    in lib.mkIf wsl-bridge.enable {
      home.activation.wslBridge = lib.hm.dag.entryAfter ["writeBoundary"]
        (builtins.concatStringsSep "\n"
          ((lib.mapAttrsToList
            (from: { directory, ... }: "mkdir -p ${directory wsl-bridge.paths}")
            wsl-bridge.map)
          ++ (lib.mapAttrsToList
            (from: { directory, filename }: ''
              if [ -e ${directory wsl-bridge.paths}/${filename} ]; then
                chmod +w ${directory wsl-bridge.paths}/${filename}
              fi
            '')
            wsl-bridge.map)
          ++ (lib.mapAttrsToList
            (from: { directory, filename }: "cp ${from} ${directory wsl-bridge.paths}/${filename}")
            wsl-bridge.map)));
    };
}

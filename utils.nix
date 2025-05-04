{ lib, ... }: {
  mkToggle = description: default: {
    enable = lib.mkOption {
      type = lib.types.bool;
      inherit default description;
    };
  };

  mkIfOptions = options: inputs:
    lib.flatten (lib.mapAttrsToList (name: value:
      if (lib.attrByPath (lib.splitString "." name) {} options).enable
        then (if builtins.isList value
          then value
          else [value])
        else []
      ) inputs);
}

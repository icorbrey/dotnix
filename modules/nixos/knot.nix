{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: {
  imports = [
    "${inputs.tangled}/nix/modules/knot.nix"
  ];

  options.modules.nixos.knot = {
    enable = lib.mkEnableOption "tangled knot";

    hostname = lib.mkOption {
      type = lib.types.str;
      example = "my.knot.com";
      description = "Hostname for the knot server";
    };

    owner = lib.mkOption {
      type = lib.types.str;
      default = config.modules.nixos.global.did;
      example = "did:plc:qfpnj4og54vl56wngdriaxug";
      description = "DID of the knot owner";
    };
  };

  config = let
    knot = config.modules.nixos.knot;
    backups = config.modules.nixos.backups;
  in
    lib.mkIf knot.enable (lib.mkMerge [
      {
        services.tangled.knot = {
          enable = true;
          package = inputs.tangled.packages.${pkgs.system}.knot;
          server.hostname = knot.hostname;
          server.owner = knot.owner;
        };
      }
      (lib.mkIf backups.enable {
        modules.nixos.backups.paths = [config.services.tangled.knot.stateDir];
      })
    ]);
}

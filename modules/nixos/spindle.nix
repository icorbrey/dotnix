{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: {
  imports = [
    "${inputs.tangled}/nix/modules/spindle.nix"
  ];

  options.modules.nixos.spindle = {
    enable = lib.mkEnableOption "tangled spindle";

    hostname = lib.mkOption {
      type = lib.types.str;
      example = "my.spindle.com";
      description = "Hostname for the spindle server";
    };

    owner = lib.mkOption {
      type = lib.types.str;
      default = config.modules.nixos.global.did;
      example = "did:plc:qfpnj4og54vl56wngdriaxug";
      description = "DID of the spindle owner";
    };
  };

  config = let
    spindle = config.modules.nixos.spindle;
    backups = config.modules.nixos.backups;

    sqliteDumpDir = "/var/backup/sqlite";
  in
    lib.mkIf spindle.enable (lib.mkMerge [
      {
        services.tangled.spindle = {
          enable = true;
          package = inputs.tangled.packages.${pkgs.system}.spindle;
          server.hostname = spindle.hostname;
          server.owner = spindle.owner;
        };
      }
      (lib.mkIf backups.enable {
        environment.systemPackages = [pkgs.sqlite];

        modules.nixos.backups.paths = [sqliteDumpDir];

        modules.nixos.backups.prepareCommands = [
          "mkdir -p ${sqliteDumpDir}"
          "sqlite3 ${config.services.tangled.spindle.server.dbPath} \".backup ${sqliteDumpDir}/spindle.db\""
        ];
      })
    ]);
}

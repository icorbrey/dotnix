{
  config,
  lib,
  ...
}: {
  options.modules.nixos.backups = {
    enable = lib.mkEnableOption "restic backups";

    bucket = lib.mkOption {
      type = lib.types.str;
      description = "Backblaze B2 bucket name";
    };

    passwordFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to restic repository encryption password file";
    };

    environmentFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to file containing B2_ACCOUNT_ID and B2_ACCOUNT_KEY";
    };

    paths = lib.mkOption {
      type = with lib.types; listOf str;
      default = [];
      description = "Paths to include in backups; modules opt in by appending here";
    };

    prepareCommands = lib.mkOption {
      type = with lib.types; listOf str;
      default = [];
      description = "Commands to run before backup; modules opt in by appending here";
    };
  };

  config = let
    backups = config.modules.nixos.backups;
  in
    lib.mkIf backups.enable {
      services.restic.backups.main = {
        repository = "b2:${backups.bucket}";
        passwordFile = backups.passwordFile;
        environmentFile = backups.environmentFile;
        paths = backups.paths;
        backupPrepareCommand =
          if backups.prepareCommands != []
          then lib.concatStringsSep "\n" backups.prepareCommands
          else null;
        timerConfig = {
          OnCalendar = "hourly";
          Persistent = true;
        };
        pruneOpts = [
          "--keep-hourly 24"
          "--keep-daily 7"
          "--keep-weekly 4"
          "--keep-monthly 6"
        ];
      };
    };
}

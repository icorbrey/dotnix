{
  config,
  lib,
  ...
}: {
  options.modules.nixos.docker = {
    enable = lib.mkEnableOption "Docker";

    users = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Users to add to the docker group.";
    };
  };

  config = let
    docker = config.modules.nixos.docker;
  in
    lib.mkIf docker.enable {
      virtualisation.docker.enable = true;

      users.users = lib.genAttrs docker.users (_: {
        extraGroups = ["docker"];
      });
    };
}

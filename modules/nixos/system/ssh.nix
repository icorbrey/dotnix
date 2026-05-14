{
  config,
  lib,
  ...
}: {
  options.modules.nixos.system.ssh = {
    enable = lib.mkEnableOption "OpenSSH server";
  };

  config = let
    ssh = config.modules.nixos.system.ssh;
  in
    lib.mkIf ssh.enable {
      services.openssh.enable = true;
    };
}

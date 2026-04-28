{
  config,
  lib,
  pkgs,
  ...
}: let
  aerospace = config.modules.home.aerospace;
in {
  options.modules.home.aerospace = {
    enable = lib.mkEnableOption "AeroSpace tiling window manager";
  };

  config = lib.mkIf aerospace.enable {
    assertions = [
      {
        assertion = pkgs.stdenv.hostPlatform.isDarwin;
        message = "`modules.home.aerospace.enable` requires a Darwin host.";
      }
    ];

    home.packages = [pkgs.aerospace];

    home.file.".aerospace.toml".source = ./config.toml;

    launchd.agents.aerospace = {
      enable = true;
      config = {
        ProgramArguments = ["${pkgs.aerospace}/bin/aerospace"];
        KeepAlive = true;
        ProcessType = "Interactive";
        LimitLoadToSessionType = "Aqua";
        StandardOutPath = "/tmp/aerospace.out.log";
        StandardErrorPath = "/tmp/aerospace.err.log";
      };
    };
  };
}

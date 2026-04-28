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

    home.packages = [pkgs.aerospace pkgs.autoraise];

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

    launchd.agents.autoraise = {
      enable = true;
      config = {
        ProgramArguments = ["${pkgs.autoraise}/bin/AutoRaise" "-delay" "0"];
        KeepAlive = true;
        ProcessType = "Interactive";
        LimitLoadToSessionType = "Aqua";
        StandardOutPath = "/tmp/autoraise.out.log";
        StandardErrorPath = "/tmp/autoraise.err.log";
      };
    };
  };
}

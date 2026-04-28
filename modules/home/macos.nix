{
  config,
  lib,
  pkgs,
  ...
}: let
  macos = config.modules.home.macos;
  splitScrolling = macos.mouse.natural != macos.touchpad.natural;
  scrollReverserAppPath =
    if macos.scrollReverser.package == null
    then macos.scrollReverser.appPath
    else "${macos.scrollReverser.package}/Applications/Scroll Reverser.app";
in {
  options.modules.home.macos = {
    configure = lib.mkEnableOption "macOS-specific configuration";

    scrollReverser = {
      appPath = lib.mkOption {
        type = lib.types.str;
        default = "/Applications/Scroll Reverser.app";
        description = "Path to an externally installed Scroll Reverser app bundle.";
      };

      package = lib.mkOption {
        type = lib.types.nullOr lib.types.package;
        default = null;
        description = "Optional Scroll Reverser package to install instead of using an externally installed app.";
      };
    };

    mouse.natural = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether mouse scrolling should use natural scrolling.";
    };

    touchpad.natural = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether touchpad scrolling should use natural scrolling.";
    };
  };

  config = lib.mkIf macos.configure (lib.mkMerge [
    {
      assertions = [
        {
          assertion = pkgs.stdenv.hostPlatform.isDarwin;
          message = "`modules.home.macos.configure` requires a Darwin host.";
        }
      ];

      targets.darwin.defaults.NSGlobalDomain."com.apple.swipescrolldirection" = macos.touchpad.natural;

      targets.darwin.defaults."com.pilotmoon.scroll-reverser" = {
        InvertScrollingOn = splitScrolling;
        ReverseX = splitScrolling;
        ReverseY = splitScrolling;
        ReverseMouse = splitScrolling;
        ReverseTrackpad = false;
        StartAtLogin = false;
      };
    }

    (lib.mkIf splitScrolling {
      home.packages = lib.optional (macos.scrollReverser.package != null) macos.scrollReverser.package;

      launchd.agents.scroll-reverser = {
        enable = true;
        config = {
          ProgramArguments = [
            "/bin/sh"
            "-lc"
            ''
              app=${lib.escapeShellArg scrollReverserAppPath}
              if [ -d "$app" ]; then
                exec /usr/bin/open -g "$app"
              fi
            ''
          ];
          RunAtLoad = true;
          LimitLoadToSessionType = "Aqua";
        };
      };
    })
  ]);
}

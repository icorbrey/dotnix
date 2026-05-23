{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.home.wallpaper-engine;

  # Build the per-output argument pairs:
  #   --screen-root <output> --bg <wallpaper-id-or-path>
  outputArgs = lib.concatLists (
    lib.mapAttrsToList (
      output: wallpaper: [
        "--screen-root"
        output
        "--bg"
        (toString wallpaper)
      ]
    )
    cfg.outputs
  );

  # Span groups stretch a single wallpaper across multiple outputs:
  #   --screen-span <out1>,<out2>,... --bg <wallpaper>
  # Requires linux-wallpaperengine with PR #557 merged or applied
  # (see overlay in overlays.nix).
  spanArgs = lib.concatLists (
    map (group: [
      "--screen-span"
      (lib.concatStringsSep "," group.outputs)
      "--bg"
      (toString group.wallpaper)
    ])
    cfg.spanGroups
  );

  globalArgs =
    lib.optionals cfg.silent ["--silent"]
    ++ lib.optional (cfg.volume != null) "--volume=${toString cfg.volume}"
    ++ lib.optional (cfg.fps != null) "--fps=${toString cfg.fps}"
    ++ lib.optional (cfg.scaling != null) "--scaling=${cfg.scaling}"
    ++ lib.optional (cfg.clamping != null) "--clamping=${cfg.clamping}"
    ++ lib.optional cfg.noAutomute "--noautomute"
    ++ lib.optional cfg.disableMouse "--disable-mouse"
    ++ lib.optional cfg.noFullscreenPause "--no-fullscreen-pause"
    ++ cfg.extraArgs;

  execStart =
    "${cfg.package}/bin/linux-wallpaperengine "
    + lib.escapeShellArgs (globalArgs ++ spanArgs ++ outputArgs);
in {
  options.modules.home.wallpaper-engine = {
    enable = lib.mkEnableOption "Wallpaper Engine wallpapers via linux-wallpaperengine";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.linux-wallpaperengine;
      defaultText = lib.literalExpression "pkgs.linux-wallpaperengine";
      description = "The linux-wallpaperengine package to use.";
    };

    outputs = lib.mkOption {
      type = lib.types.attrsOf (lib.types.either lib.types.str lib.types.path);
      default = {};
      example = lib.literalExpression ''
        {
          "DP-1" = "2876332886"; # Steam Workshop ID
          "HDMI-A-2" = ./wallpapers/my-scene; # path into the flake
        }
      '';
      description = ''
        Mapping of Niri output name to a Wallpaper Engine wallpaper.
        Values are passed to `--bg`. Each value may be:

        - A Steam Workshop ID string (e.g. `"2233920230"`) — the numeric
          folder name under
          `~/.local/share/Steam/steamapps/workshop/content/431960/`.
        - An absolute path string, or a Nix path (e.g. `./wallpapers/foo`)
          which Nix will copy into the store. The path must point at a
          directory containing `project.json` and the wallpaper assets
          (e.g. `scene.pkg`).
      '';
    };

    spanGroups = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          outputs = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            description = "Output names to stretch the wallpaper across, in left-to-right order.";
          };
          wallpaper = lib.mkOption {
            type = lib.types.either lib.types.str lib.types.path;
            description = ''
              Workshop ID, absolute path string, or Nix path to the
              wallpaper directory to span across the outputs.
            '';
          };
        };
      });
      default = [];
      example = lib.literalExpression ''
        [
          {
            outputs = [ "HDMI-A-2" "DP-1" "DP-2" ];
            wallpaper = ./wallpapers/sand-dunes;
          }
        ]
      '';
      description = ''
        Groups of outputs to stretch a single wallpaper across, using
        linux-wallpaperengine's --screen-span flag.

        This requires linux-wallpaperengine to be built with PR #557
        (Almamu/linux-wallpaperengine#557) applied. See the overlay in
        overlays.nix that pins to that PR's branch.

        Outputs listed here should not also appear in `outputs`.
      '';
    };

    silent = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Mute audio from wallpapers.";
    };

    volume = lib.mkOption {
      type = lib.types.nullOr (lib.types.ints.between 0 100);
      default = 15;
      description = "Audio volume (0-100). Set to null to leave at default.";
    };

    fps = lib.mkOption {
      type = lib.types.nullOr lib.types.ints.positive;
      default = 30;
      description = "Frame rate cap. Set to null to leave at default.";
    };

    scaling = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum ["stretch" "fit" "fill" "default"]);
      default = "fill";
      description = "How wallpapers are scaled to the output.";
    };

    clamping = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum ["clamp" "border" "repeat"]);
      default = null;
      description = "Texture clamping mode at output edges.";
    };

    noAutomute = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Don't auto-mute wallpaper audio when other apps play sound.";
    };

    disableMouse = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Disable mouse interaction with wallpapers (recommended on Wayland).";
    };

    noFullscreenPause = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Keep wallpapers running even when a fullscreen window is focused.";
    };

    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Additional arguments passed to linux-wallpaperengine.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = let
      spanOutputs = lib.concatLists (map (g: g.outputs) cfg.spanGroups);
    in [
      {
        assertion = cfg.outputs != {} || cfg.spanGroups != [];
        message = "modules.home.wallpaper-engine must define at least one entry in `outputs` or `spanGroups`.";
      }
      {
        assertion =
          lib.intersectLists spanOutputs (lib.attrNames cfg.outputs) == [];
        message = "modules.home.wallpaper-engine: outputs cannot appear in both `outputs` and `spanGroups`.";
      }
      {
        assertion = (lib.unique spanOutputs) == spanOutputs;
        message = "modules.home.wallpaper-engine: an output cannot appear in more than one span group.";
      }
    ];

    home.packages = [cfg.package];

    systemd.user.services.wallpaper-engine = {
      Unit = {
        Description = "Wallpaper Engine wallpapers via linux-wallpaperengine";
        PartOf = ["graphical-session.target"];
        After = ["graphical-session.target"];
        ConditionEnvironment = [
          "XDG_CURRENT_DESKTOP=niri"
        ];
      };

      Service = {
        ExecStart = execStart;
        Restart = "on-failure";
        RestartSec = 3;
        # linux-wallpaperengine can be memory hungry; let the OOM killer
        # prefer it over more important session services.
        OOMScoreAdjust = 500;
      };

      Install = {
        WantedBy = ["graphical-session.target"];
      };
    };
  };
}

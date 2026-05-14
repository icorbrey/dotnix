{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.home.claude-code;
  skills = config.modules.home.skills.definitions;
in {
  options.modules.home.claude-code = {
    enable = lib.mkEnableOption "claude-code";

    skills.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Deploy skills from the global registry to Claude Code's skills directory.";
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      home.packages = [pkgs.claude-code];
    }
    (lib.mkIf cfg.skills.enable {
      home.file = lib.mapAttrs' (name: skill:
        lib.nameValuePair
        ".claude/skills/${name}/SKILL.md"
        {source = skill.source;})
      skills;
    })
  ]);
}

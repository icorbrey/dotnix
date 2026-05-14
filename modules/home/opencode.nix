{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.home.opencode;
  skills = config.modules.home.skills.definitions;
in {
  options.modules.home.opencode = {
    enable = lib.mkEnableOption "opencode";

    skills.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Deploy skills from the global registry to OpenCode's skills directory.";
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      home.packages = [pkgs.opencode];
    }
    (lib.mkIf cfg.skills.enable {
      home.file = lib.mapAttrs' (name: skill:
        lib.nameValuePair
        ".config/opencode/skills/${name}/SKILL.md"
        {source = skill.source;})
      skills;
    })
  ]);
}

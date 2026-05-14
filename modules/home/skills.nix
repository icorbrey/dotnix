{
  config,
  lib,
  ...
}: let
  cfg = config.modules.home.skills;

  # OpenCode/Claude skill name rules:
  #   - 1-64 characters
  #   - lowercase alphanumeric with single hyphen separators
  #   - no leading/trailing/consecutive hyphens
  validName = name:
    (builtins.match "[a-z0-9]+(-[a-z0-9]+)*" name != null)
    && (builtins.stringLength name >= 1)
    && (builtins.stringLength name <= 64);

  skillModule = lib.types.submodule ({name, ...}: {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
        default = name;
        description = ''
          The skill name. Must match the attribute key and follow the
          regex ^[a-z0-9]+(-[a-z0-9]+)*$ (1-64 characters).
        '';
      };

      source = lib.mkOption {
        type = lib.types.path;
        description = ''
          Path to the skill's SKILL.md file. The file must contain its own
          YAML frontmatter (name, description, ...). It is copied verbatim
          by consuming agent harnesses.
        '';
        example = lib.literalExpression "./jujutsu/skill.md";
      };
    };
  });
in {
  options.modules.home.skills = {
    definitions = lib.mkOption {
      type = lib.types.attrsOf skillModule;
      default = {};
      description = ''
        Global registry of agent skills, keyed by skill name. Any module may
        contribute skills here; agent harness modules (e.g. OpenCode, Claude
        Code) read this registry and deploy each SKILL.md into their expected
        location.
      '';
      example = lib.literalExpression ''
        {
          jujutsu.source = ./jujutsu/skill.md;
        }
      '';
    };
  };

  config = {
    assertions =
      lib.mapAttrsToList (key: skill: {
        assertion = key == skill.name;
        message = "skills: definition key '${key}' must match its name '${skill.name}'.";
      })
      cfg.definitions
      ++ lib.mapAttrsToList (key: skill: {
        assertion = validName skill.name;
        message = "skills: invalid skill name '${skill.name}'. Names must be 1-64 chars, lowercase alphanumeric with single-hyphen separators (regex: ^[a-z0-9]+(-[a-z0-9]+)*$).";
      })
      cfg.definitions;
  };
}

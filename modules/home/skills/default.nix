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

  # Auto-discover any general skill living under modules/home/skills/.
  # Skills with a tool home (e.g. rust, jujutsu) register themselves from
  # their tool module instead — keep them where the tool lives so the
  # skill's content and the toolchain it documents stay co-located. Skills
  # that have no tool home (epistemic / workflow / process rules) go here
  # and are deployed unconditionally.
  #
  # Two equivalent source forms are accepted:
  #
  #   skills/<slug>.md          — flat file. Default for pure-markdown skills.
  #   skills/<slug>/skill.md    — directory. Use when the skill bundles
  #                                reference files (templates, scripts,
  #                                worked examples) the SKILL.md refers to.
  #
  # The harness deploys both forms to the same path
  # (`<harness>/skills/<slug>/SKILL.md`), so a skill graduates from flat to
  # directory with a single `mv` and no consumer-facing churn. A slug may
  # not be declared in both forms simultaneously; the assertion below
  # catches that.
  thisDir = builtins.readDir ./.;

  flatSkills = lib.mapAttrs' (filename: _: {
    name = lib.removeSuffix ".md" filename;
    value = {source = ./. + "/${filename}";};
  }) (lib.filterAttrs (
    name: type:
      type == "regular"
      && lib.hasSuffix ".md" name
      && name != "README.md"
  )
  thisDir);

  directorySkills = lib.mapAttrs (name: _: {
    source = ./. + "/${name}/skill.md";
  }) (lib.filterAttrs (
    name: type:
      type == "directory"
      && builtins.pathExists (./. + "/${name}/skill.md")
  )
  thisDir);

  collisions = builtins.intersectAttrs flatSkills directorySkills;
  discoveredSkills = flatSkills // directorySkills;
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

        General skills under modules/home/skills/ are auto-registered. They
        may be flat (skills/<slug>.md) or directory-shaped
        (skills/<slug>/skill.md); see the file-level comment in
        skills/default.nix for the form selection rule. Tool-attached skills
        are registered from their tool module (e.g.
        modules/home/rust/default.nix).
      '';
      example = lib.literalExpression ''
        {
          jujutsu.source = ./jujutsu/skill.md;
        }
      '';
    };
  };

  config = {
    modules.home.skills.definitions = discoveredSkills;

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
      cfg.definitions
      ++ [
        {
          assertion = collisions == {};
          message = "skills: slug(s) ${lib.concatStringsSep ", " (builtins.attrNames collisions)} declared in both flat (<slug>.md) and directory (<slug>/skill.md) forms under modules/home/skills/. Pick one; the directory form supersedes only when the flat form is removed.";
        }
      ];
  };
}

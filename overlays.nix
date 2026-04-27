{
  inputs,
  system,
  ...
}: let
  optionalInputPackage = name: input: package:
    if
      input ? packages
      && builtins.hasAttr system input.packages
      && builtins.hasAttr package input.packages.${system}
    then {
      ${name} = input.packages.${system}.${package};
    }
    else {};
in [
  inputs.nur.overlays.default

  (final: prev:
    optionalInputPackage "auto-cpufreq" inputs.auto-cpufreq "default"
    // optionalInputPackage "helix" inputs.helix "default"
    // optionalInputPackage "tuicr" inputs.llm-agents "tuicr")
]

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

  helixPackage = final:
    if
      inputs.helix ? packages
      && builtins.hasAttr system inputs.helix.packages
      && builtins.hasAttr "default" inputs.helix.packages.${system}
    then let
      gotmplGrammar = final.runCommand "helix-tree-sitter-gotmpl" {} ''
        mkdir -p $out
        ln -s ${final.vimPlugins.nvim-treesitter-parsers.gotmpl}/parser/gotmpl.so $out/gotmpl.so
      '';
    in {
      helix = inputs.helix.packages.${system}.default.override {
        grammarOverlays = [
          (_: _: {
            gotmpl = gotmplGrammar;
          })
        ];
      };
    }
    else {};
in [
  inputs.nur.overlays.default

  (final: prev:
    optionalInputPackage "auto-cpufreq" inputs.auto-cpufreq "default"
    // helixPackage final
    // optionalInputPackage "tuicr" inputs.llm-agents "tuicr")
]

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
  # Upstream's flake (github:AvengeMedia/danksearch) ships a stale
  # vendorHash for the Go modules. Rebuild from the same source with
  # the correct hash so we don't have to wait on upstream.
  dsearchPackage = final:
    if inputs ? dsearch
    then {
      dsearch = final.buildGoModule {
        pname = "dsearch";
        version = "0.3.1";
        src = inputs.dsearch;
        vendorHash = "sha256-scvZWbMHAhpYWCU0xZK1E6h6sAkoXegqI1iYS44fcCg=";
        subPackages = ["cmd/dsearch"];
        ldflags = ["-s" "-w" "-X main.Version=0.3.1"];
        meta = {
          description = "Indexed filesystem search in GO";
          homepage = "https://github.com/AvengeMedia/danksearch";
          mainProgram = "dsearch";
          license = final.lib.licenses.mit;
          platforms = final.lib.platforms.unix;
        };
      };
    }
    else {};
in [
  inputs.claude-code.overlays.default
  inputs.nur.overlays.default

  (final: prev:
    optionalInputPackage "auto-cpufreq" inputs.auto-cpufreq "default"
    // helixPackage final
    // dsearchPackage final
    // optionalInputPackage "tuicr" inputs.llm-agents "tuicr")
]

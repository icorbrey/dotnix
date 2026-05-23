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
  # Override linux-wallpaperengine to pull from 0qln's fork at the tip of
  # the open PR #557 (Almamu/linux-wallpaperengine), which adds
  # --screen-span for spanning a single wallpaper across multiple
  # outputs. Drop this override once the PR lands upstream.
  linuxWallpaperenginePR557 = final: prev: {
    linux-wallpaperengine = prev.linux-wallpaperengine.overrideAttrs (old: {
      version = "0-unstable-pr557-c0f37b1";
      src = final.fetchFromGitHub {
        owner = "0qln";
        repo = "linux-wallpaperengine";
        rev = "c0f37b1aba30ec4babe08ed114d7e570cef14c08";
        fetchSubmodules = true;
        hash = "sha256-XibtF+FuYknsCr4AN4TAiN4kxZaczO9h0g/ZK2SPki4=";
      };
    });
  };
in [
  inputs.claude-code.overlays.default
  inputs.nur.overlays.default
  linuxWallpaperenginePR557

  (final: prev:
    optionalInputPackage "auto-cpufreq" inputs.auto-cpufreq "default"
    // helixPackage final
    // dsearchPackage final
    // optionalInputPackage "tuicr" inputs.llm-agents "tuicr")
]

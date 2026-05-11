{
  inputs.auto-cpufreq.url = "github:AdnanHodzic/auto-cpufreq";
  inputs.auto-cpufreq.inputs.nixpkgs.follows = "nixpkgs";

  inputs.claude-code.url = "github:sadjow/claude-code-nix";
  inputs.claude-code.inputs.nixpkgs.follows = "nixpkgs";

  inputs.dms.url = "github:AvengeMedia/DankMaterialShell/stable";
  inputs.dms.inputs.nixpkgs.follows = "nixpkgs";

  inputs.dsearch.url = "github:AvengeMedia/danksearch";
  inputs.dsearch.inputs.nixpkgs.follows = "nixpkgs";

  inputs.helix.url = "github:icorbrey/helix/custom";
  inputs.helix.inputs.nixpkgs.follows = "nixpkgs";

  inputs.home-manager.url = "github:nix-community/home-manager";
  inputs.home-manager.inputs.nixpkgs.follows = "nixpkgs";

  inputs.llm-agents.url = "github:numtide/llm-agents.nix";
  inputs.llm-agents.inputs.nixpkgs.follows = "nixpkgs";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  inputs.tangled.url = "git+https://tangled.org/tangled.org/core";

  inputs.nur.url = "github:nix-community/NUR";

  inputs."zen-browser".url = "github:youwen5/zen-browser-flake";
  inputs."zen-browser".inputs.nixpkgs.follows = "nixpkgs";

  outputs = {
    home-manager,
    claude-code,
    nixpkgs,
    ...
  } @ inputs: let
    inherit (nixpkgs) lib;

    systems =
      lib.filter
      (system: lib.hasSuffix "-linux" system || lib.hasSuffix "-darwin" system)
      lib.systems.flakeExposed;

    forAllSystems = lib.genAttrs systems;

    overlaysFor = system:
      import ./overlays.nix {
        inherit inputs system;
      };

    nixpkgsModule = system: {
      nixpkgs = {
        overlays = overlaysFor system;
        hostPlatform = lib.mkDefault system;

        config.allowUnfree = true;
      };
    };

    pkgsFor = system:
      import nixpkgs {
        inherit system;
        overlays = overlaysFor system;

        config.allowUnfree = true;
      };

    utils = import ./utils.nix {
      inherit lib;
    };

    specialArgs = {
      inherit inputs;
    };

    extraSpecialArgs = {
      inherit inputs utils;
    };

    mkHomeConfiguration = {
      modules,
      system,
    }:
      home-manager.lib.homeManagerConfiguration {
        pkgs = pkgsFor system;
        inherit extraSpecialArgs modules;
      };

    mkNixosConfiguration = {
      modules,
      system,
    }:
      nixpkgs.lib.nixosSystem {
        modules =
          modules
          ++ [
            (nixpkgsModule system)
          ];
        inherit specialArgs;
      };

    homeHosts = {
      "icorbrey@elysium" = {
        system = "x86_64-linux";
        modules = [
          inputs.dms.homeModules.dank-material-shell
          inputs.dsearch.homeModules.default
          ./hosts/elysium/home/icorbrey.nix
        ];
      };

      "icorbrey@zephyr" = {
        system = "x86_64-linux";
        modules = [
          inputs.dms.homeModules.dank-material-shell
          inputs.dsearch.homeModules.default
          ./hosts/zephyr/home/icorbrey.nix
        ];
      };

      "icorbrey@hestia" = {
        system = "aarch64-linux";
        modules = [
          inputs.dms.homeModules.dank-material-shell
          inputs.dsearch.homeModules.default
          ./hosts/hestia/home/icorbrey.nix
        ];
      };

      "isaac_corbrey@isaac-corbrey-l" = {
        system = "aarch64-darwin";
        modules = [./hosts/isaac-corbrey-l/home/isaac_corbrey.nix];
      };

      "icorbrey@csusf200" = {
        system = "x86_64-linux";
        modules = [./hosts/csusf200/home/icorbrey.nix];
      };
    };

    nixosHosts = {
      elysium = {
        system = "x86_64-linux";
        modules = [
          ./hosts/elysium/configuration.nix
        ];
      };

      zephyr = {
        system = "x86_64-linux";
        modules = [
          ./hosts/zephyr/configuration.nix
        ];
      };

      hestia = {
        system = "aarch64-linux";
        modules = [
          ./hosts/hestia/configuration.nix
        ];
      };
    };
  in {
    devShells = forAllSystems (system:
      import ./shell.nix {
        pkgs = pkgsFor system;
      });

    homeConfigurations = lib.mapAttrs (_: mkHomeConfiguration) homeHosts;

    nixosConfigurations = lib.mapAttrs (_: mkNixosConfiguration) nixosHosts;
  };
}

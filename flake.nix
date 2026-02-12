{
  inputs.auto-cpufreq.url = "github:AdnanHodzic/auto-cpufreq";
  inputs.auto-cpufreq.inputs.nixpkgs.follows = "nixpkgs";

  inputs.beads.url = "github:steveyegge/beads";
  inputs.beads.inputs.nixpkgs.follows = "nixpkgs";

  inputs.dms.url = "github:AvengeMedia/DankMaterialShell/stable";
  inputs.dms.inputs.nixpkgs.follows = "nixpkgs";

  inputs.helix.url = "github:icorbrey/helix/custom";
  inputs.helix.inputs.nixpkgs.follows = "nixpkgs";

  inputs.home-manager.url = "github:nix-community/home-manager";
  inputs.home-manager.inputs.nixpkgs.follows = "nixpkgs";

  inputs.llm-agents.url = "github:numtide/llm-agents.nix";
  inputs.llm-agents.inputs.nixpkgs.follows = "nixpkgs";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  inputs.nur.url = "github:nix-community/NUR";

  outputs = {
    home-manager,
    nixpkgs,
    ...
  } @ inputs: let
    system = "x86_64-linux";

    overlays = import ./overlays.nix {
      inherit inputs;
    };

    overlayModule.nixpkgs = {
      inherit overlays;
    };

    pkgs = import nixpkgs {
      inherit overlays system;

      config.allowUnfree = true;
    };

    utils = import ./utils.nix {
      inherit (nixpkgs) lib;
    };

    specialArgs = {
      inherit inputs;
    };

    extraSpecialArgs = {
      inherit inputs utils;
    };
  in {
    devShells.${system} = import ./shell.nix {
      inherit pkgs;
    };

    # Desktop
    homeConfigurations."icorbrey@elysium" = home-manager.lib.homeManagerConfiguration {
      modules = [./hosts/elysium/home/icorbrey.nix];
      inherit extraSpecialArgs pkgs;
    };

    # Personal laptop
    nixosConfigurations."zephyr" = nixpkgs.lib.nixosSystem {
      modules = [
        ./hosts/zephyr/configuration.nix
        overlayModule
      ];
      inherit system specialArgs;
    };
    homeConfigurations."icorbrey@zephyr" = home-manager.lib.homeManagerConfiguration {
      modules = [
        inputs.dms.homeModules.dank-material-shell
        ./hosts/zephyr/home/icorbrey.nix
      ];
      inherit extraSpecialArgs pkgs;
    };

    # Work laptop
    homeConfigurations."icorbrey@NB-99KZST3" = home-manager.lib.homeManagerConfiguration {
      modules = [./hosts/NB-99KZST3/home/icorbrey.nix];
      inherit extraSpecialArgs pkgs;
    };
  };
}

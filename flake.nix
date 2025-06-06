{
  # inputs.helix.url = "github:icorbrey-contrib/helix/feat/bufferline-context";
  # inputs.helix.inputs.nixpkgs.follows = "nixpkgs";
  
  inputs.home-manager.url = "github:nix-community/home-manager";
  inputs.home-manager.inputs.nixpkgs.follows = "nixpkgs";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/release-25.05";

  inputs.nur.url = "github:nix-community/NUR";

  outputs = { home-manager, nixpkgs, ... } @ inputs: let
    system = "x86_64-linux";

    overlays = import ./overlays.nix {
      inherit inputs;
    };

    pkgs = import nixpkgs {
      inherit overlays system;

      config.allowUnfree = true;
    };

    utils = import ./utils.nix {
      inherit (nixpkgs) lib;
    };

    extraSpecialArgs = {
      inherit inputs utils;
    };
  
  in {
    devShells.${system} = import ./shell.nix {
      inherit pkgs;
    };

    # Desktop
    homeConfigurations.elysium = home-manager.lib.homeManagerConfiguration {
      modules = [./hosts/elysium/home.nix];
      inherit extraSpecialArgs pkgs;
    };

    # Personal laptop
    homeConfigurations.zephyr = home-manager.lib.homeManagerConfiguration {
      modules = [./hosts/zephyr/home.nix];
      inherit extraSpecialArgs pkgs;
    };

    # Work laptop
    homeConfigurations.NB-99KZST3 = home-manager.lib.homeManagerConfiguration {
      modules = [./hosts/NB-99KZST3/home.nix];
      inherit extraSpecialArgs pkgs;
    };
  };
}

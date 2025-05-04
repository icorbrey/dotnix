{
  inputs.home-manager.url = "github:nix-community/home-manager";
  inputs.home-manager.inputs.nixpkgs.follows = "nixpkgs";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs";
  inputs.nur.url = "github:nixcommunity/NUR";

  output = { home-manager, ... } @ inputs: let
    system = "x86_64-linux";

    overlays = import ./overlays.nix {
      inherit inputs;
    };

    pkgs = {
      config.allowUnfree = true;

      inherit overlays system;
    };

    utils = import ./utils.nix {
      inherit lib;
    };

    extraSpecialArgs = {
      inherit inputs utils;
    };
  
  in {
    devShells.${system} = import ./shell.nix {
      inherit pkgs;
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
  }
}

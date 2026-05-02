{
  description = "NixOS, Linux, and Darwin configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, nix-darwin, ... }@inputs:
    let
      linuxSystem = "x86_64-linux";
      darwinSystem = "aarch64-darwin"; # Assuming Apple Silicon; change to x86_64-darwin if Intel
    in
    {
      # Group 1: NixOS Development Machines
      nixosConfigurations = {
        vm-nixos = nixpkgs.lib.nixosSystem {
          system = linuxSystem;
          modules = [ ./hosts/nixos/vm-nixos/configuration.nix ];
        };
        tw-nixos = nixpkgs.lib.nixosSystem {
          system = linuxSystem;
          modules = [ ./hosts/nixos/tw-nixos/configuration.nix ];
        };
        lp-nixos-mariac = nixpkgs.lib.nixosSystem {
          system = linuxSystem;
          modules = [ ./hosts/nixos/lp-nixos-mariac/configuration.nix ];
        };
      };

      # Group 2: Non-NixOS Linux Machines (Standalone Home Manager)
      homeConfigurations = {
        "dragosc@tw-fedora" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${linuxSystem};
          modules = [ ./hosts/linux/tw-fedora/home.nix ];
        };
        "dragosc@tw-ubuntu" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${linuxSystem};
          modules = [ ./hosts/linux/tw-ubuntu/home.nix ];
        };
        "dragosc@tw-omarchy" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${linuxSystem};
          modules = [ ./hosts/linux/tw-omarchy/home.nix ];
        };
        "dragosc@wsl-ubuntu" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${linuxSystem};
          modules = [ ./hosts/linux/wsl-ubuntu/home.nix ];
        };
        "dragosc@vm-ubuntu" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${linuxSystem};
          modules = [ ./hosts/linux/vm-ubuntu/home.nix ];
        };
        "dragosc@vm-fedora" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${linuxSystem};
          modules = [ ./hosts/linux/vm-fedora/home.nix ];
        };
      };

      # Group 3: macOS
      darwinConfigurations = {
        "Dragoss-MBP" = nix-darwin.lib.darwinSystem {
          system = darwinSystem;
          modules = [ ./hosts/darwin/Dragoss-MBP.lan/configuration.nix ];
        };
      };
    };
}

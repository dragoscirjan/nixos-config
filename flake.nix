{
  description = "Nix configuration — NixOS & Linux/Home Manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs:
    let
      system = "x86_64-linux";
    in
    {
      nixosConfigurations = {
        # Basic install — VM
        vm-nixos = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [ ./hosts/vm-nixos/configuration.nix ];
        };

        # Extended install — Tower workstation (AMD GPU)
        tw-nixos = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [ ./hosts/tw-nixos/configuration.nix ];
        };

        # Laptop — Maria C (Nvidia GPU) — stub, boot TBD
        lp-nixos-mariac = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [ ./hosts/lp-nixos-mariac/configuration.nix ];
        };
      };

      homeConfigurations = {
        # Tower workstation running Fedora (Home Manager only)
        "tw-fedora" = home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
            config.permittedInsecurePackages = [ "openssl-1.1.1w" ];
          };
          modules = [ ./hosts/tw-fedora/home.nix ];
        };
      };
    };
}
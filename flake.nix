{
  description = "NixOS configuration for vm-nixos and tw-nixos";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
    nixosConfigurations = {
      # Basic install - VM
      vm-nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [ ./hosts/vm-nixos/configuration.nix ];
      };

      # Extended install - Workstation
      tw-nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [ ./hosts/tw-nixos/configuration.nix ];
      };
    };
    };
}

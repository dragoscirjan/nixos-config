{
  description = "NixOS configuration — vm-nixos, tw-nixos, lp-nixos-mariac";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
  };

  outputs = { self, nixpkgs, ... }@inputs:
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
    };
}

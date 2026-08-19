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

    nix-homebrew = {
      url = "github:zhaofengli/nix-homebrew";
    };

    mac-app-util = {
      url = "github:hraban/mac-app-util";
    };

    elegant-grub2-themes = {
      url = "github:vinceliuice/Elegant-grub2-themes";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, nix-darwin, nix-homebrew, mac-app-util, ... }@inputs:
    let
      linuxSystem = "x86_64-linux";
      darwinSystem = "aarch64-darwin"; # Assuming Apple Silicon; change to x86_64-darwin if Intel
      synergyVersion = "3.6.3";

      pkgsFor = system: import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          permittedInsecurePackages = [
            "openssl-1.1.1w"
          ];
        };
      };
      linuxPkgs = pkgsFor linuxSystem;
      darwinPkgs = pkgsFor darwinSystem;
      elegantGrubThemeSource = inputs.elegant-grub2-themes.packages.${linuxSystem}.default;
      installSynergy = pkgs: pkgs.writeShellScriptBin "install-synergy" ''
        exec ${pkgs.bash}/bin/bash ${./install-synergy.sh} ${synergyVersion} "$@"
      '';
    in
    {
      # Group 1: NixOS Development Machines
      nixosConfigurations = {
        vm-nixos = nixpkgs.lib.nixosSystem {
          system = linuxSystem;
          specialArgs = { isHomeManager = false; inherit synergyVersion; };
          modules = [ ./hosts/nixos/vm-nixos/configuration.nix ];
        };
        tw-nixos = nixpkgs.lib.nixosSystem {
          system = linuxSystem;
          specialArgs = { isHomeManager = false; inherit elegantGrubThemeSource synergyVersion; };
          modules = [ ./hosts/nixos/tw-nixos/configuration.nix ];
        };
        lp-nixos-mariac = nixpkgs.lib.nixosSystem {
          system = linuxSystem;
          specialArgs = { isHomeManager = false; inherit synergyVersion; };
          modules = [ ./hosts/nixos/lp-nixos-mariac/configuration.nix ];
        };
      };

      # Group 2: Non-NixOS Linux Machines (Standalone Home Manager)
      homeConfigurations = {
        "dragosc@tw-fedora" = home-manager.lib.homeManagerConfiguration {
          pkgs = linuxPkgs;
          extraSpecialArgs = { isHomeManager = true; inherit synergyVersion; };
          modules = [ ./hosts/linux/tw-fedora/home.nix ];
        };
        "dragosc@tw-ubuntu" = home-manager.lib.homeManagerConfiguration {
          pkgs = linuxPkgs;
          extraSpecialArgs = { isHomeManager = true; inherit synergyVersion; };
          modules = [ ./hosts/linux/tw-ubuntu/home.nix ];
        };
        "dragosc@tw-omarchy" = home-manager.lib.homeManagerConfiguration {
          pkgs = linuxPkgs;
          extraSpecialArgs = { isHomeManager = true; inherit synergyVersion; };
          modules = [ ./hosts/linux/tw-omarchy/home.nix ];
        };
        "dragosc@wsl-ubuntu" = home-manager.lib.homeManagerConfiguration {
          pkgs = linuxPkgs;
          extraSpecialArgs = { isHomeManager = true; inherit synergyVersion; };
          modules = [ ./hosts/linux/wsl-ubuntu/home.nix ];
        };
        "dragosc@wsl-fedora" = home-manager.lib.homeManagerConfiguration {
          pkgs = linuxPkgs;
          extraSpecialArgs = { isHomeManager = true; inherit synergyVersion; };
          modules = [ ./hosts/linux/wsl-fedora/home.nix ];
        };
        "dragosc@vm-ubuntu" = home-manager.lib.homeManagerConfiguration {
          pkgs = linuxPkgs;
          extraSpecialArgs = { isHomeManager = true; inherit synergyVersion; };
          modules = [ ./hosts/linux/vm-ubuntu/home.nix ];
        };
        "dragosc@vm-fedora" = home-manager.lib.homeManagerConfiguration {
          pkgs = linuxPkgs;
          extraSpecialArgs = { isHomeManager = true; inherit synergyVersion; };
          modules = [ ./hosts/linux/vm-fedora/home.nix ];
        };
      };

      # Group 3: macOS
      darwinConfigurations = {
        mac-m1 = nix-darwin.lib.darwinSystem {
          system = darwinSystem;
          specialArgs = { isHomeManager = false; inherit home-manager mac-app-util synergyVersion; };
          modules = [
            nix-homebrew.darwinModules.nix-homebrew
            mac-app-util.darwinModules.default
            ./hosts/darwin/mac-m1/configuration.nix
          ];
        };
        mac-m5 = nix-darwin.lib.darwinSystem {
          system = darwinSystem;
          specialArgs = { isHomeManager = false; inherit home-manager mac-app-util synergyVersion; };
          modules = [
            nix-homebrew.darwinModules.nix-homebrew
            mac-app-util.darwinModules.default
            ./hosts/darwin/mac-m5/configuration.nix
          ];
        };
      };

      packages = {
        "${linuxSystem}".install-synergy = installSynergy linuxPkgs;
        "${darwinSystem}".install-synergy = installSynergy darwinPkgs;
      };

      lib.synergyVersion = synergyVersion;
    };
}

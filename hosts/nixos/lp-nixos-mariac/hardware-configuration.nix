# Empty hardware configuration placeholder for lp-nixos-mariac
# Run `nixos-generate-config` on target hardware and replace this file
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ ];

  # Minimal stubs so the flake evaluates without a real target machine.
  # Replace everything here with the output of `nixos-generate-config` on the laptop.
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda"; # replace after nixos-generate-config
}

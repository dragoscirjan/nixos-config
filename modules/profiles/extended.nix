# Extended Profile
# Extends basic with additional IDEs, terminals, and tools
{ config, pkgs, lib, ... }:

{
  imports = [
    ./basic.nix
  ];

  # Enable extended packages
  modules.packages = {
    browsers.extended = true;
    code-agents.extended = true;
    creative.extended = true;
    customize.extended = true;
    ide.extended = true;
    languages.extended = true;
    terminals.extended = true;
    virtual.extended = true;
  };

  # Printing: CUPS with HP drivers and wireless discovery
  modules.system.printing = {
    enable = true;
    hplip = true;
    wireless = true;
  };

  # Additional packages
  environment.systemPackages = with pkgs; [
    spotify
  ];
}

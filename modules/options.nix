# Host hardware option flags
# Used by hw/ templates to signal capabilities to app/ templates (e.g. ai.nix GPU acceleration)
{ lib, ... }:

{
  options.host.hw = {
    gpuAmd = lib.mkEnableOption "AMD GPU";
    gpuNvidia = lib.mkEnableOption "Nvidia GPU";
    gpuIntel = lib.mkEnableOption "Intel GPU";
    laptop = lib.mkEnableOption "Laptop";
    tower = lib.mkEnableOption "Tower";
  };
}

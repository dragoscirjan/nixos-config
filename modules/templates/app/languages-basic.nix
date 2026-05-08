{ pkgs, isHomeManager ? false, ... }:

let
  sharedPackages = with pkgs; [
    # JavaScript / TypeScript (Basic)
    nodejs_24

    # Python (Basic)
    python3
  ];
in
if isHomeManager then {
  home.packages = sharedPackages;
} else {
  environment.systemPackages = sharedPackages;
}

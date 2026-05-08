# AI template — extended (includes basic AI CLI tools + GUI like lmstudio)
{ pkgs, isHomeManager ? false, ... }:

let
  sharedPackages = with pkgs; [
    lmstudio
  ];
in
{
  imports = [ ./ai-llm-basic.nix ];
} // (if isHomeManager then {
  home.packages = sharedPackages;
} else {
  environment.systemPackages = sharedPackages;
})

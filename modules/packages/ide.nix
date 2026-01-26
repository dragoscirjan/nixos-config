# IDE and editor packages
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.packages.ide;
in
{
  options.modules.packages.ide = {
    enable = mkEnableOption "IDE packages";

    minimal = mkOption {
      type = types.bool;
      default = true;
      description = "Install minimal set of IDEs (vscode, neovim)";
    };

    full = mkOption {
      type = types.bool;
      default = false;
      description = "Install full set of IDEs (includes JetBrains, Sublime)";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs;
      # Minimal IDEs
      optionals cfg.minimal [
        vscode
        neovim
      ]
      ++
      # Full IDEs (additional)
      optionals cfg.full [
        jetbrains.goland
        jetbrains.webstorm
        sublime4
      ];
  };
}

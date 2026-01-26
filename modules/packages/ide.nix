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
      description = "Install minimal set of IDEs (vscode, neovim, codeium)";
    };

    full = mkOption {
      type = types.bool;
      default = false;
      description = "Install full set of IDEs (JetBrains suite, helix, cursor, etc.)";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs;
      # Minimal IDEs
      optionals cfg.minimal [
        vscode
        neovim
        codeium
        zed
      ]
      ++
      # Full IDEs (additional)
      optionals cfg.full [
        # JetBrains IDEs (corporate/ultimate versions)
        jetbrains.pycharm-professional
        jetbrains.idea-ultimate
        jetbrains.goland
        jetbrains.clion
        jetbrains.rust-rover
        jetbrains.phpstorm
        jetbrains.webstorm
        # Other editors
        sublime4
        helix
        cursor
        jetbrains.fleet
        vscode-insiders
        # TODO: antigravity, kiro - check nixpkgs availability
      ];
  };
}

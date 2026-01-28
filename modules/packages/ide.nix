# IDE and editor packages
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.packages.ide;
in
{
  options.modules.packages.ide = {
    enable = mkEnableOption "IDE packages";

    basic = mkOption {
      type = types.bool;
      default = true;
      description = "Install basic set of IDEs (vscode, neovim, codeium)";
    };

    extended = mkOption {
      type = types.bool;
      default = false;
      description = "Install extended set of IDEs (JetBrains suite, helix, cursor, etc.)";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs;
      # Basic IDEs
      optionals cfg.basic [
        vscode
        neovim
        codeium
        zed-editor
      ]
      ++
      # Extended IDEs (additional)
      optionals cfg.extended [
        # JetBrains IDEs (corporate/ultimate versions)
        jetbrains.pycharm
        jetbrains.idea
        jetbrains.goland
        jetbrains.clion
        jetbrains.rust-rover
        jetbrains.phpstorm
        jetbrains.webstorm
        # Other editors
        # sublime4  # FIXME: broken - depends on EOL openssl-1.1.1 which fails to build
        helix
        code-cursor
        kiro
        antigravity
        # jetbrains.fleet
        # vscode-insiders
      ];
  };
}

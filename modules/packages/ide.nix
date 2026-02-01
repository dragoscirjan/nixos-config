# IDE and editor packages
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.packages.ide;
in
{
  options.modules.packages.ide = {
    enable = mkEnableOption "IDE packages";

    extended = mkEnableOption "Extended IDEs (JetBrains suite, helix, cursor, etc.)";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs;
      # Basic IDEs (always installed when enabled)
      [
        codeium
        neovim
        vscode
        zed-editor
      ]
      ++
      # Extended IDEs
      optionals cfg.extended [
        # JetBrains IDEs
        android-studio
        jetbrains.clion
        jetbrains.goland
        jetbrains.idea
        jetbrains.phpstorm
        jetbrains.pycharm
        jetbrains.rust-rover
        jetbrains.webstorm
        # Other editors
        antigravity
        code-cursor
        helix
        kiro
        # jetbrains.fleet
        # vscode-insiders
      ];

    # Extended IDEs via Flatpak
    modules.system.flatpak.packages = mkIf cfg.extended [
      "com.sublimetext.three" # Sublime Text (flatpak version works, nixpkgs broken due to EOL openssl)
    ];
  };
}

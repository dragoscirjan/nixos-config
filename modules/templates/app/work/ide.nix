# Work/IDE template — editors and IDEs
{ config, pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; [
    # Text editors
    codeium
    helix
    neovim
    vscode
    zed-editor

    # Extended editors / AI-assisted
    antigravity # antigravity (formerly Cursor-community package)
    code-cursor
    kiro

    # JetBrains IDEs
    android-studio
    jetbrains.clion
    jetbrains.goland
    jetbrains.idea-ultimate
    jetbrains.phpstorm
    jetbrains.pycharm-professional
    jetbrains.rust-rover
    jetbrains.webstorm
  ];

  # Sublime Text via Flatpak (nixpkgs build broken due to EOL openssl)
  modules.flatpak.packages = [
    "com.sublimetext.three"
  ];
}

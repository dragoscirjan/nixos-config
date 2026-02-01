# Extended Profile
# Extends basic with additional IDEs and terminals
# Adds: intellij-goland, intellij-webstorm, sublime-text, wezterm
{ config, pkgs, lib, ... }:

{
  imports = [
    ./basic.nix
  ];

  # Browsers: enable extended set (adds chrome, brave) - Zen via Flatpak
  modules.packages.browsers.extended = lib.mkForce true;

  # IDEs: enable extended set (adds goland, webstorm, sublime)
  modules.packages.ide.extended = lib.mkForce true;

  # Languages: enable extended set (adds clang zig)
  modules.packages.languages.extended = lib.mkForce true;

  # Terminals: enable extended set (adds wezterm)
  modules.packages.terminals.extended = lib.mkForce true;

  # Virtualization: enable docker (in addition to podman)
  modules.packages.virtual.extended = lib.mkForce true;

  # Virtualization: enable jujutsu, gh (in addition to podman)
  modules.packages.vcs.extended = lib.mkForce true;

  # Additional packages
  environment.systemPackages = with pkgs; [
    spotify
  ];

  # Flatpak: add Zen Browser, Google Chrome and Synergy to extended profile
  modules.system.flatpak = {
    enable = true;
    packages = [
      "app.zen_browser.zen"
      "com.google.Chrome"
      "org.kde.Platform/x86_64/6.9"
      "https://symless.com/synergy/download/package/synergy-personal-v3/flatpak/synergy-3.5.1-linux-noble-x86_64.flatpak"
    ];
  };

  # Creative: enable extended set (adds lunacy, inkscape)
  modules.packages.creative.extended = lib.mkForce true;

  # Code Agents: enable all code agents
  modules.packages.code-agents = {
    enable = true;
    opencode = true;
    claude-code = true;
    gemini-cli = true;
    codex = true;
    copilot-cli = true;
  };

  # Printing: enable CUPS with HP drivers and wireless discovery
  modules.system.printing = {
    enable = true;
    hplip = true; # HP OfficeJet Pro 9010 series driver
    wireless = true; # Enable network printer discovery via Avahi
  };
}

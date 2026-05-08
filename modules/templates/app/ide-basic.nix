{ config, pkgs, isHomeManager ? false, ... }:

let
  # Determine install path based on environment (requires root for /opt, user for $HOME)
  nvimInstallDir = if isHomeManager then "$HOME/.local/opt/nvim-linux-x86_64" else "/opt/nvim-linux-x86_64";
  nvimBaseDir = if isHomeManager then "$HOME/.local/opt" else "/opt";

  sharedPackages = with pkgs; [
    zed-editor
    (writeShellScriptBin "nvim" ''
      exec ${nvimInstallDir}/bin/nvim "$@"
    '')
  ];

  # The core download script (runs in standard bash)
  downloadScript = ''
    mkdir -p ${nvimBaseDir}
    echo "Fetching latest Neovim to ${nvimBaseDir}..."
    ${pkgs.curl}/bin/curl -sSL -o /tmp/nvim-linux-x86_64.tar.gz https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
    rm -rf ${nvimInstallDir}
    PATH=${pkgs.gzip}/bin:$PATH ${pkgs.gnutar}/bin/tar -C ${nvimBaseDir} -xzf /tmp/nvim-linux-x86_64.tar.gz
    rm -f /tmp/nvim-linux-x86_64.tar.gz
  '';

in
if isHomeManager then {
  home.packages = sharedPackages;

  # Home Manager equivalent of system.activationScripts
  home.activation.installNeovimLatest = config.lib.dag.entryAfter ["writeBoundary"] ''
    ${downloadScript}
  '';
} else {
  environment.systemPackages = sharedPackages;

  # NixOS native activation script
  system.activationScripts.installNeovimLatest = ''
    ${downloadScript}
  '';
}

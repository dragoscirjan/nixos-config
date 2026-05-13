{ config, pkgs, isHomeManager ? false, ... }:

let
  # Determine install path based on environment
  # We now place Neovim in the local folder on both NixOS and Home Manager environments
  nvimInstallDir = if isHomeManager then "$HOME/.local/opt/nvim-linux-x86_64" else "/home/dragosc/.local/opt/nvim-linux-x86_64";
  nvimBaseDir = if isHomeManager then "$HOME/.local/opt" else "/home/dragosc/.local/opt";

  sharedPackages = with pkgs; [
    zed-editor
    (writeShellScriptBin "nvim" ''
      exec ${nvimInstallDir}/bin/nvim "$@"
    '')
  ];

  # The core download script (runs in standard bash)
  downloadScript = ''
    mkdir -p ${nvimBaseDir}
    chmod 755 ${nvimBaseDir}
    echo "Fetching latest Neovim to ${nvimBaseDir}..."
    if ${pkgs.curl}/bin/curl -f -sSL --connect-timeout 10 -o /tmp/nvim-linux-x86_64.tar.gz https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz; then
      rm -rf ${nvimInstallDir}
      PATH=${pkgs.gzip}/bin:$PATH ${pkgs.gnutar}/bin/tar -C ${nvimBaseDir} -xzf /tmp/nvim-linux-x86_64.tar.gz
      chmod -R 755 ${nvimInstallDir}
      rm -f /tmp/nvim-linux-x86_64.tar.gz
    else
      echo "Network unavailable or download failed. Keeping existing Neovim installation."
    fi
    ${if !isHomeManager then "chown -R dragosc:dragosc ${nvimBaseDir}" else ""}
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

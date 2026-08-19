# Shared core CLI utilities across all OSs
{ pkgs }: with pkgs; [
  # Network
  curl
  wget

  # File/directory utilities
  bat
  eza
  fd
  fzf
  ripgrep
  tree
  yazi
  jq
  yq

  # Crypto
  openssl

  # Shell environment
  go-task
  mise

  # System monitoring
  btop
  fastfetch

  # Screenshot / audio control
  flameshot
  pavucontrol

  # Archiving
  zip
  unzip
  p7zip
  gzip
  bzip2
  xz
  zstd
  gnutar
  pigz
  lz4
  rar
  unar

  # Networking
  net-tools
  tmate

]

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
]

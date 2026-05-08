{ pkgs }: 

(map (f: pkgs.nerd-fonts.${f}) [
  "fira-code"
  "jetbrains-mono"
  "monofur"
  "roboto-mono"
  "sauce-code-pro"
  "ubuntu"
  "hasklug"
  "inconsolata"
]) ++ (with pkgs; [
  noto-fonts
  noto-fonts-color-emoji
])

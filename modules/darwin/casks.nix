# Homebrew casks — GUI macOS apps not available/sensible via nixpkgs
# (proper /Applications + Spotlight integration, unlike nix-installed .app
# bundles which need extra tooling like mac-app-util to show up there).
#
# NOTE: "Owly" was requested too, but it's Mac App Store-only (confirmed:
# "Owly: Prevent Display Sleep", https://apps.apple.com/us/app/owly-prevent-display-sleep/id882812218)
# — not installable via a Homebrew cask (would need `mas` + a signed-in
# Apple ID, out of scope for this declarative flow). Install it manually
# via the App Store for now.
[
  "alfred" # launcher / productivity
  "rectangle" # window snapping/tiling
  "aldente" # battery charge-limiter

  # Browsers: on NixOS, Chrome + Zen come via Flatpak (browsers.nix's
  # NixOS-only branch), which doesn't exist/apply on Darwin. Homebrew
  # casks are the equivalent here. Cask token for Zen is "zen" (not
  # "zen-browser" — that's a former/aliased token).
  "google-chrome"
  "zen"
]

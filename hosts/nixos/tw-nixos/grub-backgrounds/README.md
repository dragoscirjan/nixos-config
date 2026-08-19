# GRUB Backgrounds

Place portrait images for the `tw-nixos` Elegant GRUB theme in this directory.

- Use lowercase `.jpg`, `.jpeg`, `.png`, or `.webp` extensions.
- Prefer a 3:4 portrait ratio, such as 1200x1600.
- Files are sorted by name. The local calendar day's epoch-day number modulo
  the number of images selects one deterministically.
- The selector runs at system startup and daily, preparing the background for
  the next GRUB boot. Adding or removing images updates the modulo automatically.
- Images are center-cropped into the left pane of the Window layout without
  stretching; a blurred copy fills the background.
- Elegant's logo and branding overlays are disabled.

When this directory has no supported images, the upstream Wave background is
used as the fallback.

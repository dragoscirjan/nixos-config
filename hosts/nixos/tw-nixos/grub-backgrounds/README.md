# GRUB Backgrounds

Place local portrait images for the `tw-nixos` Elegant GRUB theme in this directory.
They are loaded at runtime and intentionally excluded from Git and the Nix store.

- Use lowercase `.jpg`, `.jpeg`, `.png`, or `.webp` extensions.
- Prefer a 3:4 portrait ratio, such as 1200x1600.
- One image is selected randomly on each run. The previous selection is stored
  under `/var/lib/grub-background-rotation` and excluded when at least two
  images are available, preventing consecutive repeats.
- The selector runs once after each GRUB installation. It does not run during
  startup or on a timer, so the selected image remains unchanged until the next
  rebuild. The rendered image is used for both the theme and GRUB's fallback
  splash to avoid a default-image flash.
- The selected filename is printed during GRUB installation and stored in
  `/var/lib/grub-background-rotation/last-background`.
- Images are center-cropped into the left pane of the Window layout without
  stretching; a blurred copy fills the background.
- Elegant's logo and branding overlays are disabled.

When this directory has no supported images, the upstream Wave background is
used as the fallback.

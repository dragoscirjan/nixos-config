# tw-nixos — Tower workstation (AMD GPU)
{ config, pkgs, lib, elegantGrubThemeSource, ... }:

let
  grubResolution = "3440x1440";
  # Keep unlicensed images outside the Git flake and load them at runtime.
  grubBackgroundDirectory =
    config.users.users.dragosc.home + "/.config/nixos/hosts/nixos/tw-nixos/grub-backgrounds";
  elegantThemeName = "Elegant-wave-window-left-dark";
  elegantGrubTheme = pkgs.stdenvNoCC.mkDerivation {
    pname = "tw-nixos-elegant-grub-theme";
    version = "1";
    src = elegantGrubThemeSource;
    nativeBuildInputs = [ pkgs.bash pkgs.imagemagick pkgs.lsb-release ];

    installPhase = ''
      runHook preInstall

      mkdir -p "$out/grub/themes"
      bash ./generate.sh \
        --dest "$out/grub/themes" \
        --theme wave \
        --type window \
        --side left \
        --color dark \
        --screen 2k

      theme_dir="$out/grub/themes/${elegantThemeName}"
      substituteInPlace "$theme_dir/theme.txt" \
        --replace-fail "width = 28%" "width = 21%" \
        --replace-fail "width = 23%" "width = 20%"
      sed -i '/^+ image {$/,/^}$/d' "$theme_dir/theme.txt"
      magick "$theme_dir/background.jpg" \
        -resize "x1440" \
        -gravity center \
        -background "#24242c" \
        -extent "${grubResolution}" \
        -strip \
        -quality 92 \
        "$TMPDIR/background.jpg"
      mv "$TMPDIR/background.jpg" "$theme_dir/background.jpg"

      runHook postInstall
    '';
  };
  rotateGrubBackground = pkgs.writeShellScript "rotate-grub-background" ''
    set -euo pipefail

    background_directory=${lib.escapeShellArg grubBackgroundDirectory}
    installed_backgrounds=(
      "/boot/theme/background.jpg"
      # NixOS normalizes a .jpg splashImage to /boot/background.jpeg.
      "/boot/background.jpeg"
    )
    backgrounds=()

    if [ ! -d "$background_directory" ]; then
      echo "GRUB background directory not found: $background_directory; keeping the default"
      exit 0
    fi

    while IFS= read -r -d "" background; do
      backgrounds+=("$background")
    done < <(
      ${pkgs.findutils}/bin/find "$background_directory" -maxdepth 1 -type f \
        \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.webp" \) \
        -print0 | ${pkgs.coreutils}/bin/sort -z
    )

    background_count="''${#backgrounds[@]}"
    if [ "$background_count" -eq 0 ]; then
      echo "No supported GRUB backgrounds found in $background_directory; keeping the default"
      exit 0
    fi

    state_directory="/var/lib/grub-background-rotation"
    state_file="$state_directory/last-background"
    last_background=""
    if [ -r "$state_file" ]; then
      IFS= read -r last_background < "$state_file" || true
    fi

    candidates=()
    for background in "''${backgrounds[@]}"; do
      background_name="$(${pkgs.coreutils}/bin/basename "$background")"
      if [ "$background_name" != "$last_background" ]; then
        candidates+=("$background")
      fi
    done

    # With only one image, allow it to be selected again.
    if [ "''${#candidates[@]}" -eq 0 ]; then
      candidates=("''${backgrounds[@]}")
    fi

    candidate_count="''${#candidates[@]}"
    background_index="$(${pkgs.coreutils}/bin/shuf \
      --input-range="0-$((candidate_count - 1))" \
      --head-count=1)"
    source_background="''${candidates[$background_index]}"
    background_name="$(${pkgs.coreutils}/bin/basename "$source_background")"
    work_directory="$(${pkgs.coreutils}/bin/mktemp --directory --tmpdir=/run grub-background.XXXXXX)"
    trap '${pkgs.coreutils}/bin/rm -rf "$work_directory"' EXIT

    ${pkgs.imagemagick}/bin/magick "$source_background" \
      -auto-orient \
      -resize "3440x1440^" \
      -gravity center \
      -extent "${grubResolution}" \
      -blur 0x32 \
      -fill "#00000066" \
      -colorize 20 \
      -fill "#00000066" \
      -draw "roundrectangle 860,211 2580,1277 42,42" \
      -fill "#20202a" \
      -draw "roundrectangle 860,187 2580,1253 42,42" \
      "$work_directory/window-base.png"
    ${pkgs.imagemagick}/bin/magick "$source_background" \
      -auto-orient \
      -resize "833x1014^" \
      -gravity center \
      -extent "833x1014" \
      "$work_directory/portrait.png"
    ${pkgs.imagemagick}/bin/magick -size "833x1014" xc:none \
      -fill white \
      -draw "roundrectangle 0,0 832,1013 24,24" \
      "$work_directory/mask.png"
    ${pkgs.imagemagick}/bin/magick \
      "$work_directory/portrait.png" \
      "$work_directory/mask.png" \
      -alpha off \
      -compose CopyOpacity \
      -composite \
      "$work_directory/portrait-rounded.png"
    ${pkgs.imagemagick}/bin/magick \
      "$work_directory/window-base.png" \
      "$work_directory/portrait-rounded.png" \
      -geometry "+887+213" \
      -compose over \
      -composite \
      -strip \
      -quality 92 \
      "$work_directory/background.jpg"

    background_changed=false
    for installed_background in "''${installed_backgrounds[@]}"; do
      if [ ! -e "$installed_background" ] \
        || ! ${pkgs.diffutils}/bin/cmp --silent "$work_directory/background.jpg" "$installed_background"; then
        ${pkgs.coreutils}/bin/install -m 0644 "$work_directory/background.jpg" "$installed_background"
        background_changed=true
      fi
    done

    if [ "$background_changed" = true ]; then
      echo "Set GRUB theme and splash background to $background_name ($source_background)"
    else
      echo "GRUB theme and splash background already set to $background_name ($source_background)"
    fi

    ${pkgs.coreutils}/bin/install -d -m 0755 "$state_directory"
    printf '%s\n' "$background_name" > "$state_file"
    ${pkgs.coreutils}/bin/chmod 0644 "$state_file"
  '';
in
{
  imports = [
    ./hardware-configuration.nix
    ../../../libvirt/nixos-module.nix
    ../../../modules/nixos/common.nix
    ../../../modules/templates/app/ide.nix
    ../../../modules/templates/app/browsers.nix
    ../../../modules/templates/app/languages.nix
    ../../../modules/templates/app/terminals.nix
    ../../../modules/templates/dev/tuikit.nix
    ../../../modules/nixos/remote-control.nix
    ../../../modules/templates/app/design.nix
    ../../../modules/templates/app/ai-llm.nix
    ../../../modules/templates/app/virtualization.nix
    ../../../modules/templates/app/media.nix
    ../../../modules/templates/app/office.nix
    ../../../modules/templates/app/gaming.nix
    ../../../modules/templates/hw/tower.nix
    ../../../modules/templates/hw/gpu-amd.nix
    ../../../modules/nixos/ai-mcps.nix
  ];

  # ── Developer Projects ────────────────────────────────────────────────────
  devProjects.mcpTuikit = true;

  # ── Boot: UEFI GRUB with Windows on a separate EFI partition ──────────────
  boot.loader = {
    systemd-boot.enable = false;
    grub = {
      enable = true;
      efiSupport = true;
      device = "nodev";
      theme = "${elegantGrubTheme}/grub/themes/${elegantThemeName}";
      splashImage = "${elegantGrubTheme}/grub/themes/${elegantThemeName}/background.jpg";
      # GRUB replaces /boot/theme from the store on every bootloader install,
      # so select a new background only after that copy has completed.
      extraInstallCommands = ''
        ${rotateGrubBackground}
      '';
      gfxmodeEfi = "${grubResolution},2560x1440,auto";
      gfxmodeBios = "${grubResolution},2560x1440,auto";
      extraConfig = ''
        insmod gfxterm
        insmod png
      '';
      extraEntries = ''
        menuentry "Windows 11 Pro" --class windows --class os {
          insmod part_gpt
          insmod fat
          insmod search_fs_uuid
          insmod chain
          search --no-floppy --fs-uuid --set=root 08B4-6E26
          chainloader /EFI/Microsoft/Boot/bootmgfw.efi
        }
      '';
    };
    efi.canTouchEfiVariables = true;
  };

  # ── Networking ────────────────────────────────────────────────────────────
  networking.hostName = "tw-nixos";
  networking.nameservers = [ "192.168.86.1" "8.8.8.8" ];
  networking.firewall.allowedTCPPorts = [ 22 24800 24802 ];

  # ── Printing: HP network printer discovery ────────────────────────────────
  services.printing.browsing = true;
  services.printing.browsed.enable = true;
  environment.systemPackages = with pkgs; [
    system-config-printer # printer management GUI
    hplip # hp-setup tool for HP printer configuration
    poppler-utils # provides pdfsig for validating PDF signatures
  ];

  # Smart-card middleware for certificate-based authentication and signing.
  services.pcscd.enable = true;
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTR{idVendor}=="0529", ATTR{idProduct}=="0620", GROUP="pcscd", MODE="0660"
  '';
  environment.etc."firefox/policies/policies.json".text = builtins.toJSON {
    policies.SecurityDevices.Add."OpenSC certSIGN" = "${pkgs.opensc}/lib/opensc-pkcs11.so";
  };

  # ── Bluetooth ─────────────────────────────────────────────────────────────
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings.General.Enable = "Source,Sink,Media,Socket";
  };
  services.blueman.enable = true;

  # ── Audio: HDA Intel power-save + PipeWire tuning ────────────────────────
  # Disable power-save to prevent audio crashes after suspend/idle
  boot.extraModprobeConfig = ''
    options snd_hda_intel power_save=0 power_save_controller=N
  '';

  services.pipewire.extraConfig.pipewire."92-low-latency" = {
    "context.properties" = {
      "default.clock.rate" = 48000;
      "default.clock.allowed-rates" = [ 44100 48000 ];
      "default.clock.quantum" = 1024;
      "default.clock.min-quantum" = 32;
      "default.clock.max-quantum" = 2048;
    };
  };

  services.pipewire.wireplumber.extraConfig."51-alsa-disable-suspend" = {
    "monitor.alsa.rules" = [
      {
        matches = [
          { "node.name" = "~alsa_output.*"; }
          { "node.name" = "~alsa_input.*"; }
        ];
        actions.update-props = {
          "session.suspend-timeout-seconds" = 0;
          "api.alsa.headroom" = 1024;
        };
      }
    ];
  };

  system.stateVersion = "24.11";
}

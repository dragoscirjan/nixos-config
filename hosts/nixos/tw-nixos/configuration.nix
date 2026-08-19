# tw-nixos — Tower workstation (AMD GPU)
{ config, pkgs, lib, elegantGrubThemeSource, ... }:

let
  grubResolution = "3440x1440";
  grubBackgroundDirectory = ./grub-backgrounds;
  grubBackgroundFiles = builtins.readDir grubBackgroundDirectory;
  isSupportedBackground = name:
    grubBackgroundFiles.${name} == "regular"
    && lib.any (extension: lib.hasSuffix extension name) [ ".jpg" ".jpeg" ".png" ".webp" ];
  grubBackgroundNames = lib.sort builtins.lessThan (
    lib.filter isSupportedBackground (builtins.attrNames grubBackgroundFiles)
  );
  grubBackgroundCount = builtins.length grubBackgroundNames;
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
        /tmp/grub-background-base.jpg

      compose_background() {
        source_image="$1"
        destination="$2"

        magick "$source_image" \
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
          /tmp/grub-window-base.png
        magick "$source_image" \
          -auto-orient \
          -resize "833x1014^" \
          -gravity center \
          -extent "833x1014" \
          /tmp/grub-portrait.png
        magick -size "833x1014" xc:none \
          -fill white \
          -draw "roundrectangle 0,0 832,1013 24,24" \
          /tmp/grub-mask.png
        magick /tmp/grub-portrait.png /tmp/grub-mask.png \
          -alpha off \
          -compose CopyOpacity \
          -composite \
          /tmp/grub-portrait-rounded.png
        magick /tmp/grub-window-base.png /tmp/grub-portrait-rounded.png \
          -geometry "+887+213" \
          -compose over \
          -composite \
          -strip \
          -quality 92 \
          "$destination"
      }

      mkdir -p "$out/backgrounds"
      ${lib.concatStringsSep "\n" (lib.genList (index:
        let
          backgroundName = builtins.elemAt grubBackgroundNames index;
        in
        ''compose_background "${grubBackgroundDirectory + "/${backgroundName}"}" "$out/backgrounds/${toString index}.jpg"''
      ) grubBackgroundCount)}

      ${if grubBackgroundCount == 0 then
        ''magick /tmp/grub-background-base.jpg -strip -quality 92 "$theme_dir/background.jpg"''
      else
        ''cp "$out/backgrounds/0.jpg" "$theme_dir/background.jpg"''}

      runHook postInstall
    '';
  };
  rotateGrubBackground = pkgs.writeShellScript "rotate-grub-background" ''
    set -eu

    current_date="$(${pkgs.coreutils}/bin/date +%F)"
    epoch_seconds="$(${pkgs.coreutils}/bin/date --utc --date="$current_date" +%s)"
    background_index=$((epoch_seconds / 86400 % ${toString grubBackgroundCount}))
    source_background="${elegantGrubTheme}/backgrounds/$background_index.jpg"
    installed_background="/boot/theme/background.jpg"

    if [ ! -e "$installed_background" ] || ! ${pkgs.diffutils}/bin/cmp --silent "$source_background" "$installed_background"; then
      ${pkgs.coreutils}/bin/install -m 0644 "$source_background" "$installed_background"
    fi
  '';
in
{
  imports = [
    ./hardware-configuration.nix
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

  systemd.services.grub-background-rotation = lib.mkIf (grubBackgroundCount > 0) {
    description = "Select today's deterministic GRUB background";
    wantedBy = [ "multi-user.target" ];
    after = [ "local-fs.target" ];
    unitConfig.ConditionPathIsDirectory = "/boot/theme";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = rotateGrubBackground;
    };
  };

  systemd.timers.grub-background-rotation = lib.mkIf (grubBackgroundCount > 0) {
    description = "Update the deterministic GRUB background daily";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
      Unit = "grub-background-rotation.service";
    };
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
  ];

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

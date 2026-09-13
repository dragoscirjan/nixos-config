# Flatpak utility module
# Provides services.flatpak + an aggregated package list that templates contribute to
{ config, lib, pkgs, ... }:

let
  cfg = config.modules.flatpak;
in
{
  options.modules.flatpak = {
    enable = lib.mkEnableOption "Flatpak support";
    packages = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Flatpak application IDs (or direct URLs) to install from Flathub.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.flatpak.enable = true;

    systemd.services = {
      "flatpak-install" = {
        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" "flatpak.service" ];
        requires = [ "network-online.target" ];
        path = [ pkgs.flatpak ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = pkgs.writeShellScript "flatpak-install" ''
            ${pkgs.flatpak}/bin/flatpak remote-add --if-not-exists flathub \
              https://dl.flathub.org/repo/flathub.flatpakrepo
            ${lib.concatMapStringsSep "\n" (pkg:
              if lib.hasPrefix "http://" pkg || lib.hasPrefix "https://" pkg then
                ''
                  TMP_FLATPAK=$(mktemp --suffix=.flatpak)
                  if [[ "${pkg}" == https://symless.com/synergy/download/package/* ]]; then
                    PACKAGE_PAGE=$(mktemp)
                    ${pkgs.curl}/bin/curl -fsSL "${pkg}" -o "$PACKAGE_PAGE"
                    TOKEN=$(${pkgs.gnugrep}/bin/grep -o 'token\\":\\"[^\\]*' "$PACKAGE_PAGE" | ${pkgs.coreutils}/bin/head -n1 | ${pkgs.gnused}/bin/sed 's/^token\\":\\"//')
                    if [[ -z "$TOKEN" ]]; then
                      echo "Could not extract Synergy download token from ${pkg}" >&2
                      rm -f "$TMP_FLATPAK" "$PACKAGE_PAGE"
                      exit 1
                    fi
                    FILE_NAME="$(${pkgs.coreutils}/bin/basename "${pkg}")"
                    ${pkgs.curl}/bin/curl -fsSL "https://symless.com/synergy/api/download/$FILE_NAME?token=$TOKEN" -o "$TMP_FLATPAK"
                    rm -f "$PACKAGE_PAGE"
                  else
                    ${pkgs.curl}/bin/curl -fsSL "${pkg}" -o "$TMP_FLATPAK"
                  fi
                  ${pkgs.flatpak}/bin/flatpak install --system --noninteractive "$TMP_FLATPAK" || true
                  rm -f "$TMP_FLATPAK"
                ''
              else if lib.hasSuffix ".flatpak" pkg then
                "${pkgs.flatpak}/bin/flatpak install --system --noninteractive ${pkg} || true"
              else
                "${pkgs.flatpak}/bin/flatpak install --system --noninteractive flathub ${pkg} || true"
            ) cfg.packages}
          '';
        };
      };

      "flatpak-update" = {
        description = "Update system Flatpak applications and runtimes";
        after = [ "network-online.target" "flatpak-install.service" ];
        wants = [ "network-online.target" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.flatpak}/bin/flatpak update --system --noninteractive";
        };
      };
    };

    systemd.timers."flatpak-update" = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
        RandomizedDelaySec = "1h";
      };
    };
  };
}

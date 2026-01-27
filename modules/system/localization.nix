# System localization configuration
{ config, lib, pkgs, ... }:

{
  options.modules.system.localization = {
    enable = lib.mkEnableOption "System localization settings";

    timezone = lib.mkOption {
      type = lib.types.str;
      default = "Europe/Bucharest";
      description = "System timezone";
    };

    locale = lib.mkOption {
      type = lib.types.str;
      default = "en_US.UTF-8";
      description = "System locale";
    };

    keyboardLayout = lib.mkOption {
      type = lib.types.str;
      default = "us";
      description = "Keyboard layout";
    };

    keyboardVariant = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Keyboard variant";
    };
  };

  config = lib.mkIf config.modules.system.localization.enable {
    # Timezone
    time.timeZone = config.modules.system.localization.timezone;

    # Locale
    i18n.defaultLocale = config.modules.system.localization.locale;
    i18n.extraLocaleSettings = {
      LC_ADDRESS = config.modules.system.localization.locale;
      LC_IDENTIFICATION = config.modules.system.localization.locale;
      LC_MEASUREMENT = config.modules.system.localization.locale;
      LC_MONETARY = config.modules.system.localization.locale;
      LC_NAME = config.modules.system.localization.locale;
      LC_NUMERIC = config.modules.system.localization.locale;
      LC_PAPER = config.modules.system.localization.locale;
      LC_TELEPHONE = config.modules.system.localization.locale;
      LC_TIME = config.modules.system.localization.locale;
    };

    # Console keymap
    console.keyMap = if config.modules.system.localization.keyboardLayout == "us" 
      then "us" 
      else config.modules.system.localization.keyboardLayout;

    # X11 keyboard layout
    services.xserver.xkb = {
      layout = config.modules.system.localization.keyboardLayout;
      variant = config.modules.system.localization.keyboardVariant;
    };
  };
}
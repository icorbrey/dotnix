{ config, lib, ... }: {
  options.modules.nixos.system.i18n = {
    locale = lib.mkOption {
      default = "en_US.UTF-8";
      type = lib.types.str;
    };
  };

  config = let i18n = config.modules.nixos.system.i18n;
    in {
      i18n.defaultLocale = i18n.locale;
      i18n.extraLocaleSettings = {
        LC_IDENTIFICATION = i18n.locale;
        LC_MEASUREMENT = i18n.locale;
        LC_TELEPHONE = i18n.locale;
        LC_MONETARY = i18n.locale;
        LC_ADDRESS = i18n.locale;
        LC_NUMERIC = i18n.locale;
        LC_PAPER = i18n.locale;
        LC_NAME = i18n.locale;
        LC_TIME = i18n.locale;
      };
    };
}

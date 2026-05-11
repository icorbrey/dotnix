{lib, ...}: {
  options.modules.nixos.global = {
    did = lib.mkOption {
      type = with lib.types; nullOr str;
      default = null;
      example = "did:plc:qfpnj4og54vl56wngdriaxug";
      description = "AT Protocol DID for this host's owner";
    };
  };
}

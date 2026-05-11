{
  config,
  lib,
  ...
}: {
  options.modules.nixos.ddns = {
    enable = lib.mkEnableOption "ddns";

    domains = lib.mkOption {
      type = with lib.types; listOf str;
      default = [];
      description = "List of domains to keep updated; root and wildcard records are created for each";
    };

    apiKeyFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to a file containing the Porkbun API key";
    };

    secretApiKeyFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to a file containing the Porkbun secret API key";
    };
  };

  config = let
    ddns = config.modules.nixos.ddns;
  in
    lib.mkIf ddns.enable {
      services.oink = {
        enable = true;
        inherit (ddns) apiKeyFile secretApiKeyFile;
        domains = lib.concatMap (domain: [
          { inherit domain; subdomain = "@"; }
          { inherit domain; subdomain = "*"; }
        ]) ddns.domains;
      };
    };
}

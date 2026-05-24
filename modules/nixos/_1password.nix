{
  config,
  lib,
  ...
}: {
  options.modules.nixos._1password = {
    enable = lib.mkEnableOption "1Password";
  };

  config = let
    inherit (config.modules.nixos) _1password firefox zen;
    browsers =
      lib.optional firefox.enable "firefox"
      ++ lib.optionals zen.enable ["zen" "zen-bin"];
  in
    lib.mkMerge [
      {
        programs._1password.enable = true;
        programs._1password-gui.enable = true;
        programs._1password-gui.polkitPolicyOwners = ["icorbrey"];
      }
      (lib.mkIf (0 < builtins.length browsers) {
        environment.etc."1password/custom_allowed_browsers" = {
          text = lib.strings.concatLines browsers;
          mode = "0755";
        };
      })
    ];
}

{
  config,
  lib,
  pkgs,
  utils,
  ...
}: {
  options.modules.home.rust = {
    enable = lib.mkEnableOption "rust";

    samply = utils.mkToggle "samply" true;
    bacon = utils.mkToggle "bacon" true;
    gcc = utils.mkToggle "gcc" true;
  };

  config = let
    rust = config.modules.home.rust;
  in
    lib.mkIf rust.enable {
      home.packages =
        (utils.mkIfOptions rust {
          samply = pkgs.samply;
          bacon = pkgs.bacon;
          gcc = pkgs.gcc;
        })
        ++ [
          pkgs.rustup
        ];
    };
}

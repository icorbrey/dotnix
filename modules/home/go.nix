{
  config,
  lib,
  pkgs,
  utils,
  ...
}: {
  options.modules.home.go = {
    enable = lib.mkEnableOption "go";

    gopls = utils.mkToggle "gopls" true;
    delve = utils.mkToggle "delve" true;
    staticcheck = utils.mkToggle "staticcheck" true;
  };

  config = let
    go = config.modules.home.go;
    helix = config.modules.home.helix;
  in
    lib.mkIf go.enable (lib.mkMerge [
      {
        home.packages =
          (utils.mkIfOptions go {
            gopls = pkgs.gopls;
            delve = pkgs.delve;
            staticcheck = pkgs.go-tools;
          })
          ++ [
            pkgs.go
          ];
      }
      (lib.mkIf helix.enable {
        programs.helix.languages.language = [
          {
            name = "go";
            formatter.command = "gofmt";
          }
        ];
      })
    ]);
}

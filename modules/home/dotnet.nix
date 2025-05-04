{ config, lib, pkgs, utils, ... }: {
  options.modules.home.dotnet = {
    enable = lib.mkEnableOption "dotnet";

    omnisharp = lib.mkToggle "omnisharp" true;

    sdk."6" = utils.mkToggle ".NET 6.0 SDK" true;
    sdk."7" = utils.mkToggle ".NET 7.0 SDK" true;
    sdk."8" = utils.mkToggle ".NET 8.0 SDK" true;
    sdk."9" = utils.mkToggle ".NET 9.0 SDK" true;
    sdk."10" = utils.mkToggle ".NET 10.0 SDK" true;
  };

  config = let dotnet = config.modules.home.dotnet;
    in lib.mkIf dotnet.enable {
      home.packages = utils.mkIfOptions dotnet {
        omnisharp = pkgs.omnisharp-roslyn;

        sdk."6" = pkgs.dotnet-sdk_6;
        sdk."7" = pkgs.dotnet-sdk_7;
        sdk."8" = pkgs.dotnet-sdk; # Not sure why this isn't pkgs.dotnet-sdk_8
        sdk."9" = pkgs.dotnet-sdk_9;
        sdk."10" = pkgs.dotnet-sdk_10;
      };
    };
}

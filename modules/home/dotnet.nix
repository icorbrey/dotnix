{ config, lib, pkgs, utils, ... }: {
  options.modules.home.dotnet = {
    enable = lib.mkEnableOption "dotnet";

    sdk = utils.mkToggle "dotnet SDK" true;
    sdkPackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      # Default to current supported SDKs; legacy/EOL versions (6/7) are only
      # added when allowInsecure is enabled.
      default =
        builtins.filter (pkg: pkg != null) [
          (if pkgs ? dotnet-sdk_9 then pkgs.dotnet-sdk_9 else null)
          (if pkgs ? dotnet-sdk_8 then pkgs.dotnet-sdk_8 else null)
        ];
      description = "List of .NET SDK packages to install.";
      defaultText = "Supported SDKs (8/9 on unstable)";
    };
    omnisharp = utils.mkToggle "omnisharp" true;
    allowInsecure = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Allow installing insecure/EOL SDKs (e.g. 6.x).";
    };
  };

  config = let dotnet = config.modules.home.dotnet;
      allKnownSdkPkgs =
        builtins.filter (pkg: pkg != null) [
          (if pkgs ? dotnet-sdk_9 then pkgs.dotnet-sdk_9 else null)
          (if pkgs ? dotnet-sdk_8 then pkgs.dotnet-sdk_8 else null)
          (if pkgs ? dotnet-sdk_7 then pkgs.dotnet-sdk_7 else null)
          (if pkgs ? dotnet-sdk_6 then pkgs.dotnet-sdk_6 else null)
        ];

      insecureSdks =
        builtins.filter (pkg: pkg.meta.insecure or false) allKnownSdkPkgs;

      sdkSelection =
        if dotnet.allowInsecure
          then dotnet.sdkPackages
          else builtins.filter (pkg: !(pkg.meta.insecure or false)) dotnet.sdkPackages;

      resolvedSdks =
        lib.unique (sdkSelection ++ lib.optionals dotnet.allowInsecure insecureSdks);

      combinedSdks =
        lib.optional (dotnet.sdk.enable && resolvedSdks != [])
          (pkgs.dotnetCorePackages.combinePackages resolvedSdks);
    in lib.mkIf dotnet.enable {
      home.packages =
        (utils.mkIfOptions dotnet {
          omnisharp = pkgs.omnisharp-roslyn;
        }) ++ combinedSdks;

      nixpkgs.config.permittedInsecurePackages = lib.mkIf dotnet.allowInsecure
        (map (pkg: "${pkg.pname}-${pkg.version}") insecureSdks);
    };
}

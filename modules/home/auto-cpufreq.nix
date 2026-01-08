{
  config,
  lib,
  pkgs,
  ...
}: {
  options.modules.home.auto-cpufreq = {
    enable = lib.mkEnableOption "auto-cpufreq";
  };

  config = let
    auto-cpufreq = config.modules.home.auto-cpufreq;
  in
    lib.mkIf auto-cpufreq.enable {
      home.packages = [
        pkgs.auto-cpufreq
      ];
    };
}

{
  config,
  lib,
  ...
}: {
  options.modules.nixos.sessions.niri = {
    enable = lib.mkEnableOption "niri";
  };

  config = let
    niri = config.modules.nixos.sessions.niri;
  in
    lib.mkIf niri.enable {
      programs.niri.enable = true;

      # Tie Noctalia to the niri user service so it only starts (and restarts)
      # alongside niri, instead of every graphical session like Plasma.
      services.noctalia-shell = {
        enable = true;
        target = "niri.service";
      };
    };
}

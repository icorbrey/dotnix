{ config, lib, ... }: {
  options.modules.nixos.sessions.niri = {
    enable = lib.mkEnableOption "niri";
  };

  config = let niri = config.modules.nixos.sessions.niri;
    in lib.mkIf niri.enable {
      programs.niri.enable = true;
    };
}

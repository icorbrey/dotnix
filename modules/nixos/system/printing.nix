{
  config,
  lib,
  ...
}: {
  options.modules.nixos.system.printing = {
    enable = lib.mkEnableOption "Printing";
  };

  config = let
    printing = config.modules.nixos.system.printing;
  in
    lib.mkIf printing.enable {
      services.printing.enable = true;
    };
}

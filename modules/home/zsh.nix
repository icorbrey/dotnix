{
  config,
  lib,
  ...
}: {
  options.modules.home.zsh = {
    enable = lib.mkEnableOption "zsh";
  };

  config = lib.mkIf config.modules.home.zsh.enable {
    programs.zsh.enable = true;
    programs.zsh.initContent = ''
      export PATH="$HOME/.local/bin:$PATH"
    '';
  };
}

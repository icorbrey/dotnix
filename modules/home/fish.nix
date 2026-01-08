{
  config,
  lib,
  pkgs,
  ...
}: {
  options.modules.home.fish = {
    enable = lib.mkEnableOption "fish";
  };

  config = let
    fish = config.modules.home.fish;
  in
    lib.mkIf fish.enable (lib.mkMerge [
      {
        programs.fish.enable = true;
        programs.fish.interactiveShellInit = ''
          set fish_greeting
          set -gx EDITOR ${config.modules.home.global.editor}
        '';
        programs.fish.functions.fish_user_key_bindings = ''
          bind \co edit_command_buffer
        '';
        programs.fish.shellAliases = lib.mkMerge [
          config.modules.home.global.shellAliases
          {clear = "clear -x";} # Don't get rid of command outputs
        ];
      }
      (lib.mkIf (config.modules.home.global.shell == "fish") {
        programs.bash.enable = true;
        programs.bash.initExtra = ''
          if [[ $(${pkgs.procps}/bin/ps --no-header --pid=$PPID --format=comm) != "fish" && -z ''${BASH_EXECUTION_STRING} ]]; then
            shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
            exec ${pkgs.fish}/bin/fish $LOGIN_OPTION
          fi
        '';
      })
    ]);
}

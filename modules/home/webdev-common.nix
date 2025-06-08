{ config, lib, pkgs, utils, ... }: {
  options.modules.home.webdev-common = {
    enable = lib.mkEnableOption "webdev-common";

    javascript = utils.mkToggle "javascript" true;
    typescript = utils.mkToggle "typescript" true;
    svelte = utils.mkToggle "svelte" true;
    astro = utils.mkToggle "astro" true;
    fnm = utils.mkToggle "fnm" true;

    vue = utils.mkToggle "vue" false;
  };

  config = let webdev-common = config.modules.home.webdev-common;
    in lib.mkIf webdev-common.enable (lib.mkMerge [
      {
        home.packages = utils.mkIfOptions webdev-common {
          javascript = pkgs.vscode-langservers-extracted;
          typescript = pkgs.typescript-language-server;
          svelte = pkgs.svelte-language-server;
          astro = pkgs.astro-language-server;
          vue = pkgs.vue-language-server;
          fnm = pkgs.fnm;
        };
      }
      (lib.mkIf (config.modules.home.fish.enable && webdev-common.fnm.enable) {
        programs.fish.interactiveShellInit = ''
          fnm env --use-on-cd --shell fish | source
        '';
      })
    ]);
}

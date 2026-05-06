{
  config,
  lib,
  pkgs,
  utils,
  ...
}: {
  options.modules.home.webdev-common = {
    enable = lib.mkEnableOption "webdev-common";

    javascript = utils.mkToggle "javascript" true;
    typescript = utils.mkToggle "typescript" true;
    svelte = utils.mkToggle "svelte" true;
    astro = utils.mkToggle "astro" true;
    pnpm = utils.mkToggle "pnpm" true;
    yarn = utils.mkToggle "yarn" true;
    fnm = utils.mkToggle "fnm" true;
    bun = utils.mkToggle "bun" true;

    vue = utils.mkToggle "vue" false;
  };

  config = let
    webdev-common = config.modules.home.webdev-common;
    pnpmHome = "${config.home.homeDirectory}/.local/share/pnpm";
  in
    lib.mkIf webdev-common.enable (lib.mkMerge [
      {
        home.packages = utils.mkIfOptions webdev-common {
          javascript = pkgs.vscode-langservers-extracted;
          svelte = pkgs.svelte-language-server;
          astro = pkgs.astro-language-server;
          vue = pkgs.vue-language-server;
          pnpm = pkgs.pnpm;
          yarn = pkgs.yarn;
          fnm = pkgs.fnm;
          bun = pkgs.bun;
          typescript = [
            pkgs.typescript-language-server
            pkgs.typescript
          ];
        };
      }
      (lib.mkIf webdev-common.pnpm.enable {
        home.sessionVariables.PNPM_HOME = pnpmHome;
        home.sessionPath = [pnpmHome];
      })
      (lib.mkIf (config.modules.home.helix.enable && webdev-common.astro.enable) {
        programs.helix.languages.language = [
          {
            roots = ["package.json" "astro.config.mjs"];
            language-servers = ["astro-ls"];
            injection-regex = "astro";
            file-types = ["astro"];
            scope = "source.astro";
            name = "astro";
          }
        ];

        programs.helix.languages.language-server.astro-ls = {
          initOptions.typescript.tsdk = "${pkgs.typescript}/lib/node_modules/typescript/lib";
          command = "astro-ls";
          args = ["--stdio"];
        };
      })
      (lib.mkIf (config.modules.home.fish.enable && webdev-common.fnm.enable) {
        programs.fish.interactiveShellInit = ''
          ${pkgs.fnm}/bin/fnm env --use-on-cd --shell fish | source
        '';
      })
    ]);
}

{...}: {
  imports = [
    ../../../modules/home
  ];

  home.homeDirectory = "/home/icorbrey";
  home.username = "icorbrey";
  home.stateVersion = "25.05";

  modules.home = {
    home-manager.enable = true;
    wsl-bridge.enable = true;

    wsl-bridge.paths = {
      appData = "/mnt/c/Users/icorbrey/AppData/Roaming";
      userHome = "/mnt/c/Users/icorbrey";
    };

    # Global configuration
    global.shell = "fish";
    global.editor = "hx";

    # CLI
    cli-common.enable = true;
    carapace.enable = true;
    starship.enable = true;
    jujutsu.enable = true;
    nushell.enable = true;
    wezterm.enable = true;
    zellij.enable = true;
    helix.enable = true;
    fish.enable = true;

    # GUI patches
    zed.enable = true;
    zed.install = false;

    jujutsu.settings = {
      scopes = [
        {
          "--when".repositories = ["~/contrib"];
          git.fetch = ["origin" "upstream"];
          git.push = "origin";
        }
      ];

      signing.key = "~/.ssh/id_ed25519.pub";
      signing.enable = true;
    };

    # Language support
    webdev-common.enable = true;
    langs-common.enable = true;
    dotnet.enable = true;
    docker.enable = true;
    rust.enable = true;
  };
}

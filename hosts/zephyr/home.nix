{ ... }: {
  imports = [
    ../../modules/home
  ];

  home.homeDirectory = "/home/icorbrey";
  home.username = "icorbrey";
  home.stateVersion = "25.05";

  modules.home = {
    home-manager.enable = true;
    auto-cpufreq.enable = true;

    # Global configuration
    global.shell = "fish";
    global.editor = "hx";

    # CLI
    cli-common.enable = true;
    carapace.enable = true;
    starship.enable = true;
    jujutsu.enable = true;
    nushell.enable = true;
    zellij.enable = true;
    helix.enable = true;
    fish.enable = true;

    jujutsu.settings = {
      scopes = [{
        "--when".repositories = ["~/dev/forks"];
        git.fetch = ["origin" "upstream"];
        git.push = "origin";
      }];

      signing.key = "~/.ssh/id_ed25519.pub";
      signing.enable = true;
    };

    # GUI
    obsidian.enable = true;
    discord.enable = true;
    fonts.enable = true;
    steam.enable = true;

    # Language support
    webdev-common.enable = true;
    langs-common.enable = true;
    docker.enable = true;
    rust.enable = true;
  };
}

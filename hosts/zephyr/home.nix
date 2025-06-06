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
    global.editor = "hx";
    global.shell = "nu";

    # CLI
    cli-common.enable = true;
    carapace.enable = true;
    starship.enable = true;
    jujutsu.enable = true;
    nushell.enable = true;
    zellij.enable = true;
    helix.enable = true;

    jujutsu.settings.scopes = [{
      "--when".repositories = ["~/dev/forks"];
      git.fetch = ["origin" "upstream"];
      git.push = "origin";
    }];

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

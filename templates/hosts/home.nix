{ ... }: {
  imports = [
    ../../modules/home
  ];

  home.homeDirectory = "/home/icorbrey";
  home.username = "icorbrey";
  home.stateVersion = "24.11";

  modules.home = {
    home-manager.enable = true;

    # CLI
    cli-common.enable = true;
    jujutsu.enable = true;
    nushell.enable = true;
    helix.enable = true;

    # # GUI
    # obsidian.enable = true;
    # discord.enable = true;
    # fonts.enable = true;
    # steam.enable = true;

    # # Language support
    # webdev-common.enable = true;
    langs-common.enable = true;
    # rust.enable = true;
  };
}

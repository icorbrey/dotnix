{ ... }: {
  imports = [
    ../../modules/home
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
    global.editor = "hx";
    global.shell = "nu";

    # CLI applications
    cli-common.enable = true;
    carapace.enable = true;
    starship.enable = true;
    jujutsu.enable = true;
    nushell.enable = true;
    zellij.enable = true;
    helix.enable = true;

    jujutsu.settings = {
      scopes = [
        {
          "--when".repositories = ["~/dev/forks"];
          git.fetch = ["origin" "upstream"];
          git.push = "origin";
        }
        {
          "--when".repositories = ["~/dev/dib"];
          user.email = "icorbrey@ntserv.doitbestcorp.com";
          git.push-bookmark-prefix = "icorbrey/push-";
        }
      ];

      tfvc.enable = true;
      tfvc.url = "https://dev.azure.com/dibc";
    };

    # Language support
    webdev-common.enable = true;
    langs-common.enable = true;
    docker.enable = true;
    dotnet.enable = true;
    java.enable = true;
    rust.enable = true;
  };
}

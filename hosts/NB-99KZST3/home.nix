{ ... }: {
  imports = [
    ../../modules/home
  ];

  home.homeDirectory = "/home/icorbrey";
  home.username = "icorbrey";
  home.stateVersion = "24.11";
  
  modules.home = {
    home-manager.enable = true;

    # CLI applications
    cli-common.enable = true;
    carapace.enable = true;
    nushell.enable = true;
    helix.enable = true;

    jujutsu.enable = true;
    jujutsu.scopes = [
      {
        "--when".repositories = ["~/dev/forks"];
        git.fetch = "upstream";
        git.push = "origin";
      }
      {
        "--when".repositories = ["~/dev/dib"];
        user.email = "icorbrey@ntserv.doitbestcorp.com";
        git.push-bookmark-prefix = "icorbrey/push-";
      }
    ];

    # Language support
    webdev-common.enable = true;
    langs-common.enable = true;
    docker.enable = true;
    dotnet.enable = true;
    java.enable = true;
    rust.enable = true;
  };
}

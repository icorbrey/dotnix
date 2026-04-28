{...}: {
  imports = [
    ../../../modules/home
  ];

  home.homeDirectory = "/Users/isaac_corbrey";
  home.username = "isaac_corbrey";
  home.stateVersion = "25.05";

  targets.darwin = {
    copyApps.enable = true;
    linkApps.enable = false;
  };

  modules.home = {
    home-manager.enable = true;

    # Global configuration
    global.shell = "fish";
    global.editor = "hx";

    macos = {
      configure = true;
      mouse.natural = false;
      touchpad.natural = true;
    };

    # CLI applications
    cli-common.enable = true;
    starship.enable = true;
    jujutsu.enable = true;
    nushell.enable = true;
    wezterm.enable = true;
    helix.enable = true;
    fish.enable = true;
    zsh.enable = true;

    jujutsu.settings = {
      scopes = [
        {
          "--when".repositories = ["~/contrib"];
          git.fetch = ["origin" "upstream"];
          git.push = "origin";
        }
        {
          "--when".repositories = ["~/sweetwater"];
          user.email = "isaac_corbrey@sweetwater.com";
        }
      ];

      signing.key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII+dxJbJs2LiS7QAFFtJsFPsntqru8c/7V/3S+DP8H+m";
      signing.enable = true;
    };

    # Language support
    webdev-common.enable = true;
    langs-common.enable = true;
    docker.enable = true;
    java.enable = true;
    rust.enable = true;
  };
}

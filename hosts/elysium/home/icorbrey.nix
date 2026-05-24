{pkgs, ...}: {
  imports = [
    ../../../modules/home
  ];

  home.homeDirectory = "/home/icorbrey";
  home.username = "icorbrey";
  home.stateVersion = "25.05";

  modules.home = {
    home-manager.enable = true;

    # Global configuration
    global.hostName = "elysium";
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
      scopes = [
        {
          "--when".repositories = ["~/contrib"];
          git.fetch = ["origin" "upstream"];
          git.push = "origin";
        }
      ];

      signing.key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII+dxJbJs2LiS7QAFFtJsFPsntqru8c/7V/3S+DP8H+m";
      signing.program = "${pkgs._1password-gui}/share/1password/op-ssh-sign";
      signing.enable = true;
    };

    # GUI
    dank-material-shell.enable = true;
    obsidian.enable = true;
    discord.enable = true;
    wayland.enable = true;
    wezterm.enable = true;
    fonts.enable = true;
    steam.enable = true;
    niri.enable = true;

    wallpaper-engine = {
      enable = true;
      # Span "Sand dunes" (authored as a 5760x1080 triple-wide scene)
      # across all three monitors using --screen-span (PR #557).
      # Requires Wallpaper Engine installed via Steam + the wallpaper
      # subscribed; linux-wallpaperengine auto-detects WE's assets
      # folder and the workshop content directory.
      spanGroups = [
        {
          outputs = ["HDMI-A-2" "DP-1" "DP-2"];
          wallpaper = "2233920230";
        }
      ];
    };
    tailscale.enable = true;
    zed.enable = true;
    vlc.enable = true;

    # Language support
    webdev-common.enable = true;
    langs-common.enable = true;
    dotnet.enable = true;
    docker.enable = true;
    rust.enable = true;
    go.enable = true;
  };
}

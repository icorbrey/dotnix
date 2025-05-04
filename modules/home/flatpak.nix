{ config, lib, pkgs, ... }: {
  options.modules.home.flatpak = {
    enable = lib.mkEnableOption "flatpak";

    apps = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "apps to install via flatpak";
    };
  };

  config = let flatpak = config.modules.home.flatpak;
    in lib.mkIf flatpak.enable {
      home.activation = {
        flatpakSetup = lib.hm.dag.entryAfter ["writeBoundary"] ''
          if ! flatpak remote-list --user | grep -q flathub; then
            echo "Adding Flathub remote for user"
            flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
          fi
        '';

        checkForUntrackedApps = lib.hm.dag.entryAfter ["flatpakSetup"] ''
          for app in $(flatpak list --user --app --columns=application); do
            case "$app" in
              ${builtins.concatStringsSep "|" flatpak.apps})
                ;;

              *)
                echo "WARNING: $app installed outside Nix"
                ;;
            esac
          done
        '';

        installFlatpakApps = lib.hm.dag.entryAfter ["checkForUntrackedApps"]
          builtins.concatStringsSep "\n" (map (app: ''
            if ! flatpak list --user --app | grep -q ${app}; then
              echo "Installing ${app} via Flatpak"
              flatpak install --user -y flathub ${app}
            fi
          '') flatpak.apps);
      };
    };
}

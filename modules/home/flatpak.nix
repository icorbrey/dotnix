{ config, lib, ... }: {
  options.modules.home.flatpak = {
    enable = lib.mkEnableOption "flatpak";

    apps = lib.mkOption {
      # "xx.xx.xx".enable = true|false;
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = false;
          };
        };
      });
      description = "apps to install via flatpak";
    };
  };

  config = let
    flatpak = config.modules.home.flatpak;
    disabled = builtins.attrNames (lib.attrsets.filterAttrs (_: v: !v.enable) flatpak.apps);
    enabled = builtins.attrNames (lib.attrsets.filterAttr (_: v: v.enable) flatpak.apps);
  in lib.mkIf flatpak.enable {
    home.activation = {
      flatpakSetup = lib.hm.dag.entryAfter ["writeBoundary"] ''
        if ! flatpak remote-list --user | grep -q flathub; then
          echo "Adding Flathub remote for user"
          flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
        fi
      '';

      removeFlatpakApps = lib.hm.dag.entryAfter ["flatpakSetup"] ''
        for app in $(flatpak list --user --app --columns=application); do
          case "$app" in
            ${builtins.concatStringsSep "|" disabled})
              echo "Removing `$app` via Flatpak"
              flatpak uninstall --user -y flathub "$app"
              ;;

            *)
              echo "WARNING: `$app` installed outside Nix"
              ;;
          esac
        done
      '';

      installFlatpakApps = lib.hm.dag.entryAfter ["removeFlatpakApps"]
        builtins.concatStringsSep "\n" (map (app: ''
          if ! flatpak list --user --app | grep -Fxq ${app}; then
            echo "Installing `${app}` via Flatpak"
            flatpak install --user -y flathub ${app}
          fi
        '') enabled);
    };
  };
}

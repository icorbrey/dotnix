{
  config,
  lib,
  pkgs,
  ...
}: {
  options.modules.home.zed = {
    enable = lib.mkEnableOption "Zed";

    install = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to install the Zed binary via Nix.";
    };
  };

  config = let
    zed = config.modules.home.zed;
  in
    lib.mkIf zed.enable (lib.mkMerge [
      (lib.mkIf zed.install {
        home.packages = [
          pkgs.zed-editor
        ];
      })
      {
    modules.home.wsl-bridge.map = {
      "~/.config/zed/settings.json" = {
        directory = {appData, ...}: "${appData}/Zed";
        filename = "settings.json";
      };
      "~/.config/zed/keymap.json" = {
        directory = {appData, ...}: "${appData}/Zed";
        filename = "keymap.json";
      };
    };

    xdg.configFile."zed/settings.json".text = builtins.toJSON {
      tab_size = 2;
      buffer_font_fallbacks = ["RecMonoDuotone Nerd Font Mono"];
      ui_font_fallbacks = ["RecMonoDuotone Nerd Font Mono"];
      tabs.file_icons = true;
      tabs.git_status = true;
      minimap.enabled = true;
      title_bar = {
        show_menus = false;
        show_user_menu = true;
        show_sign_in = false;
        show_onboarding_banner = false;
        show_project_items = true;
        show_branch_name = false;
      };
      disable_ai = true;
      base_keymap = "VSCode";
      extensions = [
        "justfile"
        "nix"
        "rust"
        "toml"
      ];
      terminal = {
        cursor_shape = "bar";
        minimum_contrast = 0.0;
        shell = {
          program = "nu";
        };
        button = false;
      };
      prettier = {
        allowed = true;
      };
      languages = {
        Nix = {
          language_servers = [
            "nixd"
            "!nil"
          ];
        };
      };
      helix_mode = true;
      telemetry = {
        diagnostics = false;
        metrics = false;
      };
      ui_font_size = 16;
      icon_theme = "Material Icon Theme";
      buffer_font_size = 12.0;
      theme = {
        mode = "dark";
        light = "One Light";
        dark = "Ayu Dark";
      };
    };

    # Zed's Helix mode still uses vim_mode contexts for keymaps.
      xdg.configFile."zed/keymap.json".text = let
      helixBaseBindings = {
        # VSCode-style multi-cursor select next/previous.
        "ctrl-d" = ["editor::SelectNext" {replace_newest = false;}];
        "ctrl-shift-d" = ["editor::SelectPrevious" {replace_newest = false;}];

        # VSCode-style add selection above/below.
        "ctrl-alt-up" = ["editor::AddSelectionAbove" {skip_soft_wrap = true;}];
        "ctrl-alt-k" = ["editor::AddSelectionAbove" {skip_soft_wrap = true;}];
        "ctrl-alt-down" = ["editor::AddSelectionBelow" {skip_soft_wrap = true;}];
        "ctrl-alt-j" = ["editor::AddSelectionBelow" {skip_soft_wrap = true;}];

        # Move lines.
        "ctrl-j" = "editor::MoveLineDown";
        "ctrl-k" = "editor::MoveLineUp";

        # Buffer navigation.
        "alt-h" = "pane::ActivatePreviousItem";
        "alt-l" = "pane::ActivateNextItem";

        # Close buffer/pane.
        "ctrl-w" = ["pane::CloseActiveItem" {close_pinned = false;}];
        "ctrl-q" = ["pane::CloseActiveItem" {close_pinned = false;}];

        # VSCode-style find references.
        "f12" = "editor::FindAllReferences";
      };

      helixSyntaxExpandBindings = {
        # Expand/contract selection by syntax node (Tree-sitter scope).
        "alt-up" = "editor::SelectLargerSyntaxNode";
        "alt-down" = "editor::SelectSmallerSyntaxNode";
      };
    in
      builtins.toJSON [
        {
          context = "VimControl && Editor";
          bindings = {
            "ctrl-d" = ["editor::SelectNext" {replace_newest = false;}];
            "ctrl-shift-d" = ["editor::SelectPrevious" {replace_newest = false;}];
            "ctrl-w" = ["pane::CloseActiveItem" {close_pinned = false;}];
          };
        }
        {
          context = "Editor && vim_mode == normal";
          bindings =
            helixBaseBindings
            // helixSyntaxExpandBindings
            ;
        }
        {
          context = "Editor && vim_mode == visual";
          bindings =
            helixBaseBindings
            // helixSyntaxExpandBindings
            ;
        }
        {
          context = "Editor && vim_mode == insert";
          bindings = helixBaseBindings;
        }
        {
          context = "Pane";
          bindings = {
            "alt-h" = "pane::ActivatePreviousItem";
            "alt-l" = "pane::ActivateNextItem";
            "alt-f" = "workspace::ToggleZoom";
          };
        }
        {
          context = "Workspace || Terminal";
          bindings = {
            "alt-f" = "workspace::ToggleZoom";
          };
        }
      ];
      }
    ]);
}

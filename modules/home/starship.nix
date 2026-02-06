{
  config,
  lib,
  ...
}: {
  options.modules.home.starship = {
    enable = lib.mkEnableOption "starship";
  };

  config = let
    starship = config.modules.home.starship;
  in
    lib.mkIf starship.enable {
      modules.home.wsl-bridge.map = {
        "~/.config/starship.toml" = {
          directory = {userHome, ...}: "${userHome}/.config";
          filename = "starship.toml";
        };
      };

      programs.starship.enable = true;
      programs.starship.settings = let
        icons.arrow.right = builtins.fromJSON ''"\ue0b0" '';
        icons.commit = builtins.fromJSON ''"\ueabc" '';
        icons.operation = builtins.fromJSON ''"\uf013" '';
        icons.round.left = builtins.fromJSON ''"\ue0b6" '';
        icons.round.right = builtins.fromJSON ''"\ue0b4" '';

        highlight = str: bg: "[${str}](fg:black bg:${bg})";
        transition = char: bg: "[${char}](fg:prev_bg bg:${bg})";
      in {
        format = lib.strings.concatStrings [
          "$os"
          "$username"
          "$directory"
          "\${custom.jj_op}"
          "\${custom.jj_conflict}"
          "\${custom.jj_diff_added}"
          "\${custom.jj_diff_removed}"
          "$character"
        ];
        palette = "clarity_noir";

        os.disabled = false;
        os.format = lib.strings.concatStrings [
          "[${icons.round.left}](fg:red)"
          (highlight "$symbol" "red")
        ];
        os.symbols = {
          NixOS = "󱄅";
          Windows = "";
          Ubuntu = "󰕈";
          SUSE = "";
          Raspbian = "󰐿";
          Mint = "󰣭";
          Macos = "󰀵";
          Manjaro = "";
          Linux = "󰌽";
          Gentoo = "󰣨";
          Fedora = "󰣛";
          Alpine = "";
          Amazon = "";
          Android = "";
          Arch = "󰣇";
          Artix = "󰣇";
          CentOS = "";
          Debian = "󰣚";
          Redhat = "󱄛";
          RedHatEnterprise = "󱄛";
        };

        username.show_always = true;
        username.format = lib.strings.concatStrings [
          (transition icons.round.right "orange")
          (highlight " $user " "orange")
        ];

        directory.format = lib.strings.concatStrings [
          (transition icons.arrow.right "yellow")
          (highlight " $path " "yellow")
        ];
        directory.truncation_symbol = "…/";
        directory.truncation_length = 3;

        custom.jj_diff_added = {
          ignore_timeout = true;
          description = "Added lines in the current jj commit";
          when = "sh -c 'test \"$(jj show -T \"self.diff().stat().total_added()\" --no-patch --ignore-working-copy)\" -ne 0'";
          command = "jj show -T \"self.diff().stat().total_added()\" --no-patch --ignore-working-copy";
          format = lib.strings.concatStrings [
            (transition icons.arrow.right "green")
            (highlight " +$output " "green")
          ];
        };

        custom.jj_diff_removed = {
          ignore_timeout = true;
          description = "Removed lines in the current jj commit";
          when = "sh -c 'test \"$(jj show -T \"self.diff().stat().total_removed()\" --no-patch --ignore-working-copy)\" -ne 0'";
          command = "jj show -T \"self.diff().stat().total_removed()\" --no-patch --ignore-working-copy";
          format = lib.strings.concatStrings [
            (transition icons.arrow.right "red")
            (highlight " -$output " "red")
          ];
        };

        custom.jj_conflict = {
          ignore_timeout = true;
          description = "Whether the current jj worktree has conflicts";
          when = "jj resolve -l --ignore-working-copy";
          format = lib.strings.concatStrings [
            (transition icons.arrow.right "red")
            (highlight " ?? " "red")
          ];
        };

        custom.jj_op = {
          ignore_timeout = true;
          description = "The current jj operation";
          when = "jj root --ignore-working-copy";
          command = "jj op log -T 'id.short(4)' --limit 1 --no-graph --color never --ignore-working-copy";
          format = lib.strings.concatStrings [
            (transition icons.arrow.right "blue")
            (highlight " ${icons.operation} $output " "blue")
          ];
        };

        character.success_symbol = (transition icons.arrow.right "none");
        character.error_symbol = lib.strings.concatStrings [
          (transition icons.arrow.right "black")
          (transition icons.arrow.right "red")
          (transition icons.arrow.right "none")
        ];

        palettes.clarity_noir = {
          red = "#FF3B11";
          green = "#2ACD41";
          orange = "#FF9502";
          yellow = "#FFCC00";
          purple = "#B051DE";
          blue = "#027AFF";
          black = "#1E1E1E";
        };
      };
    };
}

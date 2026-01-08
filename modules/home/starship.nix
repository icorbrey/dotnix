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
          "\${custom.jj_change}"
          "\${custom.jj_conflict}"
          "\${custom.jj_op}"
          "$character"
        ];
        palette = "clarity_noir";

        os.disabled = false;
        os.format = lib.strings.concatStrings [
          "[${icons.round.left}](fg:red)"
          (highlight "$symbol" "red")
        ];
        os.symbols = {
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

        custom.jj_change = {
          ignore_timeout = true;
          description = "The current jj operation";
          when = "jj root --ignore-working-copy";
          command = "jj log -r @ --no-graph --color never -T 'change_id.shortest(1)' --ignore-working-copy";
          format = lib.strings.concatStrings [
            (transition icons.arrow.right "purple")
            (highlight " ${icons.commit} $output " "purple")
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

        character.success_symbol = "[${icons.arrow.right}](fg:prev_bg bg:none)";
        character.error_symbol = "[${icons.arrow.right}](fg:prev_bg bg:red)[${icons.arrow.right}](fg:red bg:none)";

        palettes.clarity_noir = {
          red = "#FF3B11";
          orange = "#FF9502";
          yellow = "#FFCC00";
          purple = "#B051DE";
          blue = "#027AFF";
          black = "#1E1E1E";
        };
      };
    };
}

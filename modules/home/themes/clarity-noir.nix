{ lib }: let
  def-palette = palette: { inherit palette; }
    // lib.attrsets.mapAttrs (n: _: n) palette;

  definitions = def-palette {
    background0 = "#000000";
    background1 = "#1e1e1e";
    background2 = "#282828";
    background3 = "#323232";

    foreground1 = "#dcdcdc";
    foreground2 = "#8c8c8c";
    foreground3 = "#686868";

    ui1 = "#373737";
    ui2 = "#515151";
    ui3 = "#595959";

    highlight = "#31547E";

    lightred = "#ff8f75";
    red = "#ff3b11";
    darkred = "#a81f00";

    lightorange = "#ffb54d";
    orange = "#ff9502";
    darkorange = "#b36800";

    lightyellow = "#ffe066";
    yellow = "#ffcc00";
    darkyellow = "#cc7700";

    lightgreen = "#78e386";
    green = "#2acd41";
    darkgreen = "#187725";

    lightcyan = "#62fef6";
    cyan = "#02c7be";
    darkcyan = "#01928b";

    lightblue = "#66adff";
    blue = "#027aff";
    darkblue = "#004799";

    lightpurple = "#d6a5ee";
    purple = "#b051de";
    darkpurple = "#7a20a7";

    lightpink = "#ff94a8";
    pink = "#ff2e55";
    darkpink = "#c70024";
  };

  _ = lib.mkMerge;
  fg = fg: { inherit fg; };
  bg = bg: { inherit bg; };
  mod = mod: { modifiers = [mod]; };

  crossed_out = mod "crossed_out";
  underlined = mod "underlined";
  italic = mod "italic";
  bold = mod "bold";
  dim = mod "dim";
in with definitions; {
  inherit palette;

  themes.helix = {
    inherit palette;

    rainbow = [
      darkred
      darkorange
      darkyellow
      darkgreen
      darkblue
      darkpurple
      darkpink
    ];

    "ui.background" = bg background0;
    "ui.bufferline" = _[(fg foreground1) (bg ui1)];
    "ui.bufferline.active" = _[(fg foreground1) (bg darkblue)];
    "ui.linenr" = fg foreground3;
    "ui.linenr.selected" = _[(fg foreground1) bold];
    "ui.menu" = _[(fg foreground2) (bg ui1)];
    "ui.menu.selected" = _[(fg foreground1) bold];
    "ui.picker.header.column" = _[(fg foreground1) bold italic];
    "ui.picker.header.column.active" = _[(fg pink) bold italic];
    "ui.selection" = bg background3;
    "ui.selection.primary" = bg highlight;
    "ui.statusline" = _[(fg foreground1) (bg ui1)];
    "ui.statusline.normal" = _[(fg foreground1) (bg darkblue)];
    "ui.statusline.insert" = _[(fg foreground1) (bg darkorange)];
    "ui.statusline.select" = _[(fg foreground1) (bg darkpurple)];
    "ui.text" = fg foreground1;
    "ui.text.focus" = fg foreground3;
    "ui.virtual.indent-guide" = fg background1;
    "ui.virtual.jump-label" = _[(fg pink) bold italic];
    "ui.virtual.ruler" = bg background1;

    "attribute" = fg lightyellow;
    "comment" = fg foreground2;
    "constant" = fg lightblue;
    "constant.numeric" = fg lightblue;
    "constant.character.escape" = fg foreground1;
    "function" = fg lightyellow;
    "function.macro" = fg lightgreen;
    "keyword" = fg darkorange;
    "operator" = fg purple;
    "punctuation" = fg foreground2;
    "special" = fg purple;
    "string" = fg green;
    "type" = fg foreground1;
    "variable" = fg foreground1;
    "variable.other.member" = fg lightyellow;

    "tag" = fg darkorange;
    
    "markup.heading.1" = fg red;
    "markup.heading.2" = fg orange;
    "markup.heading.3" = fg yellow;
    "markup.heading.4" = fg green;
    "markup.heading.5" = fg blue;
    "markup.heading.6" = fg purple;
    "markup.list" = fg foreground1;
    "markup.bold" = _[(fg foreground1) bold];
    "markup.italic" = _[(fg foreground1) italic];
    "markup.strikethrough" = _[(fg foreground1) crossed_out];
    "markup.link.url" = _[(fg blue) underlined];
    "markup.link.text" = fg foreground1;
    "markup.quote" = fg darkgreen;
    "markup.raw" = fg purple;

    "diff.plus" = fg green;
    "diff.delta" = fg orange;
    "diff.minus" = fg red;

    "diagnostic.info".underline = { color = foreground3; style = "curl"; };
    "diagnostic.hint".underline = { color = yellow; style = "curl"; };
    "diagnostic.warning".underline = { color = orange; style = "curl"; };
    "diagnostic.error".underline = { color = red; style = "curl"; };
    "diagnostic.deprecated" = crossed_out;
    "diagnostic.unnecessary" = dim;

    "debug" = fg foreground3;
    "info" = fg yellow;
    "hint" = fg foreground3;
    "warning" = fg orange;
    "error" = fg red;
  };
}

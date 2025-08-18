local wezterm = require 'wezterm'
local config = {}

config.font = wezterm.font "Rec Mono Duotone"
config.font_size = 10.0

config.color_scheme = "JetBrains Darcula"

config.adjust_window_size_when_changing_font_size = false
config.window_decorations = "RESIZE"
config.audible_bell = "Disabled"

config.use_fancy_tab_bar = false

config.quick_select_alphabet = "jklfdsauiohnmretcgwvpyqxbz"

config.keys = {
  {
    mods = "CTRL|SHIFT",
    key = "n",
    action = wezterm.action.PromptInputLine {
      description = "Enter name for new workspace",
      action = wezterm.action_callback(function (window, pane, line)
        if line then
          window:perform_action(
            wezterm.action.SwitchToWorkspace {
              name = line
            },
            pane
          )
        end
      end),
    },
  },
}

return config

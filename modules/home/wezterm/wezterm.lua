local wezterm = require 'wezterm'
local config = {}

config.font = wezterm.font "Rec Mono Duotone"
config.font_size = 10.0

config.color_scheme = "JetBrains Darcula"

config.adjust_window_size_when_changing_font_size = false
config.window_decorations = "RESIZE"
config.audible_bell = "Disabled"

config.use_fancy_tab_bar = false

config.pane_focus_follows_mouse = true
config.inactive_pane_hsb = {
  saturation = 1.0,
  brightness = 0.8,
}

config.quick_select_alphabet = "jklfdsauiohnmretcgwvpyqxbz"

function NavigatePaneDirection(key, direction)
  return {
    action = wezterm.action { ActivatePaneDirection=direction },
    mods = "ALT",
    key = key,
  }
end

function NavigateTabDirection(key, direction)
  return {
    action = wezterm.action { ActivateTabRelative=direction },
    mods = "CTRL|ALT",
    key = key,
  }
end

function MoveTabDirection(key, direction)
  return {
    action = wezterm.action { MoveTabRelative=direction },
    mods = "SHIFT|ALT",
    key = key,
  }
end

config.keys = {
  NavigatePaneDirection("h", "Left"),
  NavigatePaneDirection("j", "Down"),
  NavigatePaneDirection("k", "Up"),
  NavigatePaneDirection("l", "Right"),
  NavigateTabDirection("h", -1),
  NavigateTabDirection("l", 1),
  MoveTabDirection("h", -1),
  MoveTabDirection("l", 1),
  {
    action = wezterm.action.TogglePaneZoomState,
    mods = "ALT",
    key = "f",
  },
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

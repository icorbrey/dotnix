local wezterm = require 'wezterm'
local config = {}

config.font = wezterm.font "Rec Mono Duotone"
config.font_size = 11.0

config.adjust_window_size_when_changing_font_size = false
config.window_decorations = "RESIZE"
config.audible_bell = "Disabled"

config.quick_select_alphabet = "jklfdsauiohnmretcgwvpyqxbz"

return config

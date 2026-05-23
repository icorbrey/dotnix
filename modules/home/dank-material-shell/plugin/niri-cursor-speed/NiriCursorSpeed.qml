import QtQuick
import Quickshell
import qs.Modules.Plugins

PluginComponent {
  id: root

  readonly property bool mouseOverrideEnabled: pluginData.mouseOverrideEnabled ?? false
  readonly property var rawMouseSpeed: pluginData.mouseSpeedLevel ?? pluginData.mouseSpeed ?? 5
  readonly property bool touchpadOverrideEnabled: pluginData.touchpadOverrideEnabled ?? false
  readonly property var rawTouchpadSpeed: pluginData.touchpadSpeedLevel ?? pluginData.touchpadSpeed ?? 5

  Timer {
    id: applyTimer
    interval: 150
    repeat: false
    onTriggered: root.applyConfig()
  }

  onPluginDataChanged: applyTimer.restart()
  Component.onCompleted: applyTimer.restart()

  function clampPercent(value) {
    if (value < 0) {
      return 0
    }
    if (value > 100) {
      return 100
    }
    return value
  }

  function percentToSpeed(percent) {
    var clamped = clampPercent(percent)
    return (clamped / 50) - 1
  }

  function coerceSpeed(value) {
    var numeric = Number(value)
    if (isNaN(numeric)) {
      return 0.0
    }
    if (numeric >= -1.0 && numeric <= 1.0) {
      return numeric
    }
    return percentToSpeed(numeric)
  }

  function buildConfig() {
    var lines = []
    lines.push("// Managed by DMS plugin: Niri Cursor Speed")

    if (mouseOverrideEnabled || touchpadOverrideEnabled) {
      lines.push("input {")

      if (mouseOverrideEnabled) {
        var mouseSpeed = coerceSpeed(rawMouseSpeed).toFixed(2)
        // niri's input device sections are non-merging, so we must re-emit
        // the base mouse settings from modules/home/niri/config.kdl here.
        lines.push("    mouse {")
        lines.push("        accel-speed " + mouseSpeed)
        lines.push("        accel-profile \"flat\"")
        lines.push("    }")
      }

      if (touchpadOverrideEnabled) {
        var touchpadSpeed = coerceSpeed(rawTouchpadSpeed).toFixed(2)
        // niri's input device sections are non-merging, so we must re-emit
        // the base touchpad settings from modules/home/niri/config.kdl here.
        lines.push("    touchpad {")
        lines.push("        tap")
        lines.push("        natural-scroll")
        lines.push("        accel-speed " + touchpadSpeed)
        lines.push("    }")
      }

      lines.push("}")
    }

    return lines.join("\n") + "\n"
  }

  function applyConfig() {
    var content = buildConfig()
    var marker = "DMS_NIRI_INPUT_EOF"
    var script =
      "set -e\n" +
      "config_dir=\"${XDG_CONFIG_HOME:-$HOME/.config}\"\n" +
      "mkdir -p \"$config_dir/niri\"\n" +
      "cat > \"$config_dir/niri/dms-input.kdl\" <<'" + marker + "'\n" +
      content +
      marker + "\n" +
      "touch \"$config_dir/niri/config.kdl\"\n"

    Quickshell.execDetached(["bash", "-lc", script])
  }
}

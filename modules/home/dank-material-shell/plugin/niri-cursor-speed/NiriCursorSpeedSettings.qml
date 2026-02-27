import QtQuick
import qs.Common
import qs.Modules.Plugins
import qs.Widgets

PluginSettings {
  pluginId: "niriCursorSpeed"

  StyledText {
    text: "Niri Cursor Speed"
    font.pixelSize: Theme.fontSizeLarge
    font.weight: Font.Bold
    color: Theme.surfaceText
  }

  StyledText {
    text: "Adjust Niri pointer acceleration. Changes are written to ~/.config/niri/dms-input.kdl."
    font.pixelSize: Theme.fontSizeSmall
    color: Theme.surfaceVariantText
    wrapMode: Text.WordWrap
  }

  ToggleSetting {
    settingKey: "mouseOverrideEnabled"
    label: "Enable mouse override"
    description: "When enabled, DMS will write a mouse accel-speed override."
    defaultValue: false
  }

  SliderSetting {
    settingKey: "mouseSpeed"
    label: "Mouse speed"
    description: "Scale: 0% (slow, -1.0) to 100% (fast, 1.0)."
    minimum: 0
    maximum: 100
    defaultValue: 50
    unit: "%"
  }

  ToggleSetting {
    settingKey: "touchpadOverrideEnabled"
    label: "Enable touchpad override"
    description: "When enabled, DMS will write a touchpad accel-speed override."
    defaultValue: false
  }

  SliderSetting {
    settingKey: "touchpadSpeed"
    label: "Touchpad speed"
    description: "Scale: 0% (slow, -1.0) to 100% (fast, 1.0)."
    minimum: 0
    maximum: 100
    defaultValue: 50
    unit: "%"
  }
}

#!/usr/bin/env sh
set -eu

swayidle -w \
  timeout 300 'loginctl lock-session; dms ipc call lock lock' \
  timeout 600 'niri msg action power-off-monitors' \
  timeout 600 'if [ "$(cat /sys/class/power_supply/AC/online 2>/dev/null)" = "0" ]; then systemctl suspend; fi' \
  resume 'niri msg action power-on-monitors' \
  before-sleep 'loginctl lock-session; dms ipc call lock lock' \
  idlehint 300

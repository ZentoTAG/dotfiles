#!/usr/bin/env bash

CONFIG_DIR="$HOME/.config/waybar"

if ls /sys/class/power_supply/BAT* >/dev/null 2>&1; then
    exec waybar -c "$CONFIG_DIR/config-laptop.jsonc" -s "$CONFIG_DIR/style.css"
else
    exec waybar -c "$CONFIG_DIR/config-desktop.jsonc" -s "$CONFIG_DIR/style.css"
fi

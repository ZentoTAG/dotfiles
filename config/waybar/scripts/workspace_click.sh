#!/bin/bash

# Waybar передаёт текст, вытаскиваем номер
WORKSPACE=$(echo "$1" | grep -o '[0-9]')

if [[ -n "$WORKSPACE" ]]; then
    hyprctl dispatch "hl.dsp.focus({ workspace = $WORKSPACE })"
fi

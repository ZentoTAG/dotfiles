#!/bin/bash

WALLPAPER=$(grep -m 1 "^wallpaper " ~/.config/waypaper/config.ini | cut -d "=" -f2 | sed 's/^[ \t]*//;s/[ \t]*$//' | sed "s|~|$HOME|")

if [ -n "$WALLPAPER" ] && [ -f "$WALLPAPER" ]; then
    hyprctl hyprpaper preload "$WALLPAPER"
    hyprctl hyprpaper wallpaper ",$WALLPAPER"
fi

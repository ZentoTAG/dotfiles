#!/usr/bin/env bash

networks=$(nmcli -t -f SSID,SIGNAL dev wifi list | awk -F':' '{print $1 " (" $2 "%)"}' | wofi --dmenu -p "  Wi-Fi" -i -lines 10 -width 350 -location top_right -offset 5 30)

if [ -n "$networks" ]; then
    ssid=$(echo "$networks" | awk -F' (' '{print $1}')
    nmcli dev wifi connect "$ssid"
fi

#!/usr/bin/env bash

# Список сетей через wofi
networks=$(nmcli -t -f SSID,SIGNAL dev wifi list | awk -F':' '{print $1 " (" $2 "%)"}' | wofi --dmenu -p "  Wi-Fi" -i -lines 10 -width 300)

if [ -n "$networks" ]; then
    ssid=$(echo "$networks" | awk -F' (' '{print $1}')
    nmcli dev wifi connect "$ssid"
fi

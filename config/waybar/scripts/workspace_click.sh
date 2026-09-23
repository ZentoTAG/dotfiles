#!/bin/bash
# Логируем, что получили
echo "Получено: $1" >> /tmp/waybar_debug.log
hyprctl dispatch "workspace $1" >> /tmp/waybar_debug.log 2>&1

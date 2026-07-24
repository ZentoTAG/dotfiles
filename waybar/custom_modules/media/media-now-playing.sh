#!/usr/bin/env bash

text=""
i=0

while true; do
    status=$(playerctl metadata --format '{{status}}' 2>/dev/null)

    if [ "$status" == "Playing" ] || [ "$status" == "Paused" ]; then
        title=$(playerctl metadata --format '{{title}} - {{artist}}' 2>/dev/null)
        title="${title}   "  # добавляем пробелы для отступа
        len=${#title}
        i=$(( (i + 1) % len ))
        echo "${title:$i:20}"  # выводим 20 символов с прокруткой
    else
        echo ""
    fi
    sleep 0.3
done

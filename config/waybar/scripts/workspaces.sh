#!/bin/bash

# Получаем активный workspace
active=$(hyprctl activeworkspace -j | jq -r '.name')

text=""
# Формируем красивую строку для отображения
for i in {1..9}; do
    if [[ "$active" == "$i" ]]; then
        text+="${text:+ }<span foreground='#ffffff' background='#666666'> $i </span>"
    else
        text+="${text:+ }<span foreground='#888888'> $i </span>"
    fi
done

# Выводим JSON: text пойдет на экран, a alt будет содержать чистый номер активного воркспейса
jq -n --arg text "$text" --arg alt "$active" '{"text": $text, "alt": $alt}'

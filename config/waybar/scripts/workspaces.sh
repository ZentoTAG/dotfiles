#!/bin/bash

# Получаем активный workspace
active=$(hyprctl activeworkspace -j | jq -r '.name')

# Получаем все workspace и форматируем
for i in {1..9}; do
    if [[ "$active" == "$i" ]]; then
        echo -n "<span foreground='#ffffff' background='#666666'> $i </span>"
    else
        echo -n "<span foreground='#888888'> $i </span>"
    fi
done

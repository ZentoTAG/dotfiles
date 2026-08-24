# #!/bin/bash
# 
# WALLPAPER=$(grep -m 1 "^wallpaper " ~/.config/waypaper/config.ini | cut -d "=" -f2 | sed 's/^[ \t]*//;s/[ \t]*$//' | sed "s|~|$HOME|")
# 
# if [ -n "$WALLPAPER" ] && [ -f "$WALLPAPER" ]; then
#     hyprctl hyprpaper preload "$WALLPAPER"
#     hyprctl hyprpaper wallpaper ",$WALLPAPER"
# fi

LAST_WALLPAPER_FILE="$HOME/.config/waypaper/last_wallpaper.txt"
DEFAULT_WALLPAPER="$HOME/data/dotfiles/assets/backgrounds/1.webp"

WALLPAPER=$(grep -m 1 "^wallpaper " ~/.config/waypaper/config.ini | cut -d "=" -f2 | sed 's/^[ \t]*//;s/[ \t]*$//' | sed "s|~|$HOME|")

if [ -n "$WALLPAPER" ] && [ -f "$WALLPAPER" ]; then
    # Запоминаем последние обои
    echo "$WALLPAPER" > "$LAST_WALLPAPER_FILE"
    awww img "$WALLPAPER" --transition-type center --transition-duration 0.5 --transition-fps 255
else
    # Если в конфиге нет — пытаемся взять последние
    if [ -f "$LAST_WALLPAPER_FILE" ]; then
        LAST_WALLPAPER=$(cat "$LAST_WALLPAPER_FILE")
        if [ -f "$LAST_WALLPAPER" ]; then
            echo "Использую последние сохранённые обои: $LAST_WALLPAPER"
            awww img "$LAST_WALLPAPER" --transition-type center --transition-duration 0.5 --transition-fps 255
        else
            echo "Последние обои не найдены, использую дефолтный..."
            awww img "$DEFAULT_WALLPAPER" --transition-type center --transition-duration 0.5 --transition-fps 255
        fi
    else
        echo "Нет сохранённых обоев, использую дефолтный..."
        awww img "$DEFAULT_WALLPAPER" --transition-type center --transition-duration 0.5 --transition-fps 255
    fi
fi

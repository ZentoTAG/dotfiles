#!/bin/bash

# ID твоего Proton-префикса для Genshin (мы его нашли ранее)
COMPAT_ID="2166084897"
GAME_DIR="$HOME/.steam/steam/steamapps/compatdata/$COMPAT_ID/pfx/drive_c/Program Files/Genshin Impact game/GenshinImpact_Data/webCaches"

# 1. Находим самую свежую папку с версией кэша (2.57.0.0 и т.д.)
LATEST_CACHE=$(ls -1t "$GAME_DIR" 2>/dev/null | head -n 1)

if [ -z "$LATEST_CACHE" ]; then
    echo "❌ Ошибка: Не удалось найти папки с кэшем в $GAME_DIR"
    echo "Проверь, запущена ли игра и открыта ли история молитв."
    exit 1
fi

DATA_FILE="$GAME_DIR/$LATEST_CACHE/Cache/Cache_Data/data_2"

if [ ! -f "$DATA_FILE" ]; then
    echo "❌ Ошибка: Файл data_2 не найден по пути: $DATA_FILE"
    exit 1
fi

echo "🔍 Ищем ссылку в кэше версии $LATEST_CACHE..."

# 2. Вытаскиваем ссылку (используем grep -a, так как файл бинарный)
# Ищем строку, которая начинается с https и содержит gacha_info/api/getGachaLog
LINK=$(grep -a -o 'https://[^ ]*getGachaLog[^ ]*' "$DATA_FILE" | tail -n 1)

if [ -z "$LINK" ]; then
    echo "❌ Ссылка не найдена. Убедись, что ты открыл историю молитв в игре и подождал загрузки."
    exit 1
fi

# 3. Выводим ссылку в терминал
echo "✅ Ссылка найдена!"
echo "---"
echo "$LINK"
echo "---"

# 4. Пытаемся скопировать в буфер обмена
if command -v wl-copy &> /dev/null; then
    echo "$LINK" | wl-copy -n
    echo "📋 Ссылка скопирована в буфер обмена (Wayland)."
elif command -v xclip &> /dev/null; then
    echo "$LINK" | xclip -selection clipboard -n
    echo "📋 Ссылка скопирована в буфер обмена (X11)."
else
    echo "⚠️ Утилита для буфера обмена (wl-copy или xclip) не найдена."
    echo "Скопируй ссылку выше вручную."
fi

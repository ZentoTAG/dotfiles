#!/bin/bash

# Переходим в папку с репозиторием
cd /home/zento/data/dotfiles || exit

# Проверяем, есть ли изменения
if [[ -n $(git status -s) ]]; then
    # Добавляем всё
    git add -A
    # Коммитим с текущей датой
    git commit -m "auto: $(date '+%Y-%m-%d %H:%M')"
    # Пушим
    git push
    echo "✅ Запушено"
else
    echo "ℹ️ Нечего пушить"
fi

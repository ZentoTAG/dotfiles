#!/bin/bash

# Переходим в папку репозитория
cd /home/zento/data/dotfiles || exit 1

# Проверяем, есть ли изменения
if [[ -z $(git status -s) ]]; then
    echo "ℹ️ Нечего коммитить"
    exit 0
fi

# Добавляем все изменения
git add -A

# Получаем список изменённых файлов (только имена)
CHANGED_FILES=$(git diff --cached --name-only)

# Считаем количество файлов
FILE_COUNT=$(echo "$CHANGED_FILES" | wc -l)

# Формируем сообщение коммита
if [[ "$FILE_COUNT" -eq 1 ]]; then
    # Если изменён только один файл — берём его имя
    MSG="auto: $CHANGED_FILES"
else
    # Если файлов несколько — перечисляем первые 3 и указываем общее количество
    FIRST_FILES=$(echo "$CHANGED_FILES" | head -3 | tr '\n' ', ' | sed 's/, $//')
    MSG="auto: $FIRST_FILES и ещё $((FILE_COUNT - 3)) файлов"
fi

# Коммитим и пушим
git commit -m "$MSG"
git push
echo "✅ Запушено: $MSG"

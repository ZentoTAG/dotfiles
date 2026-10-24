#!/usr/bin/env bash
set -euo pipefail

# Переходим в корень репозитория относительно этого скрипта
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_DIR"

if [[ -z "$(git status --porcelain)" ]]; then
    echo "ℹ️  Нечего коммитить"
    exit 0
fi

git add -A

if git diff --cached --quiet; then
    echo "ℹ️  Нет изменений для коммита"
    exit 0
fi

mapfile -t CHANGED_FILES < <(git diff --cached --name-only)
FILE_COUNT=${#CHANGED_FILES[@]}

if (( FILE_COUNT == 1 )); then
    MSG="auto: ${CHANGED_FILES[0]}"
elif (( FILE_COUNT <= 3 )); then
    MSG="auto: $(printf '%s, ' "${CHANGED_FILES[@]}" | sed 's/, $//')"
else
    FIRST_FILES="$(printf '%s, ' "${CHANGED_FILES[@]:0:3}" | sed 's/, $//')"
    MSG="auto: $FIRST_FILES и ещё $((FILE_COUNT - 3)) файлов"
fi

git commit -m "$MSG"
git push
echo "✅ Запушено: $MSG"

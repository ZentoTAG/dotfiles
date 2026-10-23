#!/usr/bin/env bash
set -euo pipefail

# Цвета для красивого вывода
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

SRC_DIR="$HOME/data/downloads"
LOG_FILE="$HOME/.local/share/organize.log"

# Папки назначения
DIR_PICS="$HOME/data/media/pictures"
DIR_VIDS="$HOME/data/media/videos"
DIR_DOCS="$HOME/data/docs"
DIR_MUSIC="$HOME/data/media/music"
DIR_ARCH="$HOME/data/archives"
DIR_SCRIPTS="$HOME/data/dev/scripts"
DIR_INST="$HOME/data/tools/installers"

# Минимальный возраст файла в минутах (чтобы не трогать недокачанные)
MIN_AGE=15

# Счетчик
MOVED_COUNT=0
DRY_RUN=false

# Проверка аргументов
if [[ "${1:-}" == "--dry-run" || "${1:-}" == "-n" ]]; then
    DRY_RUN=true
    echo -e "${YELLOW}РЕЖИМ ПРОСМОТРА (ничего не перемещается)${NC}"
fi

# Проверка, что папка существует
if [[ ! -d "$SRC_DIR" ]]; then
    echo -e "${RED}Ошибка: папка $SRC_DIR не найдена.${NC}"
    exit 1
fi

# Создаем папки, если их нет
mkdir -p "$DIR_PICS" "$DIR_VIDS" "$DIR_DOCS" "$DIR_MUSIC" "$DIR_ARCH" "$DIR_SCRIPTS" "$DIR_INST"
mkdir -p "$(dirname "$LOG_FILE")"

log_action() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Функция для перемещения
move_file() {
    local file="$1"
    local dest_dir="$2"
    local filename
    filename="$(basename "$file")"
    local dest_path="$dest_dir/$filename"

    # Если файл с таким именем уже есть, добавляем суффикс
    if [[ -e "$dest_path" ]]; then
        local base="${filename%.*}"
        local ext="${filename##*.}"
        # Если расширения нет, ext будет равен filename, а base пустым
        if [[ "$base" == "$filename" ]]; then
            base="$filename"
            ext=""
            local counter=1
            while [[ -e "$dest_dir/${base}_${counter}" ]]; do
                ((counter++))
            done
            dest_path="$dest_dir/${base}_${counter}"
        else
            local counter=1
            while [[ -e "$dest_dir/${base}_${counter}.${ext}" ]]; do
                ((counter++))
            done
            dest_path="$dest_dir/${base}_${counter}.${ext}"
        fi
    fi

    if $DRY_RUN; then
        echo -e "  ${YELLOW}[DRY-RUN]${NC} $filename -> $dest_dir/"
    else
        mv -n "$file" "$dest_path"
        echo -e "  ${GREEN}✓${NC} $filename -> $(basename "$dest_dir")/"
        log_action "Moved: $filename -> $dest_path"
        ((MOVED_COUNT++))
    fi
}

echo "Сканирую $SRC_DIR..."
echo "Игнорирую файлы младше $MIN_AGE минут и временные файлы."
echo "----------------------------------------------------"

# Ищем файлы, исключаем скрытые, временные и слишком новые
# -mmin +15 означает "измененные более 15 минут назад"
while IFS= read -r -d '' file; do
    filename="$(basename "$file")"

    # Игнорируем временные файлы браузеров
    if [[ "$filename" == *.crdownload || "$filename" == *.part || "$filename" == *.tmp ]]; then
        continue
    fi

    # Приводим расширение к нижнему регистру для сравнения
    ext="${filename##*.}"
    ext="${ext,,}"

    case "$ext" in
        jpg|jpeg|png|webp|gif|svg|avif)
            move_file "$file" "$DIR_PICS"
            ;;
        mp4|mkv|avi|webm|mov)
            move_file "$file" "$DIR_VIDS"
            ;;
        pdf|docx|doc|xlsx|pptx|txt|md|odt|ods)
            move_file "$file" "$DIR_DOCS"
            ;;
        mp3|flac|ogg|wav|m4a)
            move_file "$file" "$DIR_MUSIC"
            ;;
        zip|tar|gz|rar|7z|xz)
            move_file "$file" "$DIR_ARCH"
            ;;
        sh|py|js|lua|fish|cpp|c|h|rs)
            move_file "$file" "$DIR_SCRIPTS"
            ;;
        exe|msi|appimage|deb|pkg|zst)
            move_file "$file" "$DIR_INST"
            ;;
        *)
            # Неизвестные файлы оставляем на месте
            ;;
    esac
done < <(find "$SRC_DIR" -maxdepth 1 -type f -mmin +$MIN_AGE -print0)

echo "----------------------------------------------------"
if $DRY_RUN; then
    echo -e "${YELLOW}Это был режим просмотра. Запусти без --dry-run, чтобы переместить файлы.${NC}"
elif [[ $MOVED_COUNT -eq 0 ]]; then
    echo "Нет файлов для перемещения (все либо новые, либо уже отсортированы)."
else
    echo -e "${GREEN}Готово! Перемещено файлов: $MOVED_COUNT${NC}"
    echo "Лог: $LOG_FILE"
fi

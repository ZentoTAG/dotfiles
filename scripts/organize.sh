#!/usr/bin/env bash
# organize.sh — раскладывает файлы из ~/data/downloads по папкам.
#
#   organize.sh            — разложить (файлы старше MIN_AGE минут)
#   organize.sh -n         — только показать, что будет перемещено
#   organize.sh --now      — не ждать MIN_AGE (взять и свежие файлы)
#
# Недокачанные файлы (.part, .crdownload, .tmp) и подпапки не трогает.
# Файлы неизвестных типов остаются на месте, но скрипт их перечислит в конце.
set -uo pipefail          # без -e: одна ошибка не должна обрывать сортировку остальных

SRC_DIR="$HOME/data/downloads"
LOG_FILE="$HOME/.local/share/organize.log"
MIN_AGE=15                # минут: не трогаем свежие, возможно ещё качаются

DIR_PICS="$HOME/data/media/pictures"
DIR_VIDS="$HOME/data/media/videos"
DIR_MUSIC="$HOME/data/media/music"
DIR_DOCS="$HOME/data/docs"
DIR_ARCH="$HOME/data/archives"
DIR_CODE="$HOME/data/dev/scripts"
DIR_INST="$HOME/data/tools/installers"

# расширение (строчными) -> папка. Дописывай свои сюда.
declare -A MAP=()
add() { local dir=$1; shift; local e; for e in "$@"; do MAP[$e]=$dir; done; }
add "$DIR_PICS"  jpg jpeg png webp gif svg avif bmp tiff heic ico
add "$DIR_VIDS"  mp4 mkv avi webm mov flv wmv m4v
add "$DIR_MUSIC" mp3 flac ogg wav m4a opus aac
add "$DIR_DOCS"  pdf doc docx odt rtf txt md tex epub fb2 djvu xls xlsx ods csv ppt pptx odp
add "$DIR_ARCH"  zip tar gz tgz bz2 xz rar 7z
add "$DIR_CODE"  sh py js ts lua fish cpp c h hpp rs go java json yaml yml toml xml html css sql
add "$DIR_INST"  exe msi appimage deb rpm pkg zst iso img apk

DRY=false
for a in "$@"; do
    case $a in
        -n|--dry-run) DRY=true ;;
        --now)        MIN_AGE=0 ;;
        -h|--help)    sed -n '2,9p' "$0"; exit 0 ;;
        *) echo "Неизвестный аргумент: $a"; exit 1 ;;
    esac
done

[[ -d $SRC_DIR ]] || { echo "Нет папки $SRC_DIR"; exit 1; }
mkdir -p "$(dirname "$LOG_FILE")"

moved=0 failed=0
declare -A unknown=()

unique_path() {    # <папка> <имя> -> свободный путь (name_1.ext, name_2.ext ...)
    local dir=$1 name=$2 base ext n=1 cand
    cand="$dir/$name"
    [[ -e $cand ]] || { echo "$cand"; return; }
    if [[ $name == *.* && $name != .* ]]; then base=${name%.*}; ext=".${name##*.}"; else base=$name; ext=""; fi
    while [[ -e "$dir/${base}_$n$ext" ]]; do n=$((n + 1)); done
    echo "$dir/${base}_$n$ext"
}

while IFS= read -r -d '' file; do
    name=${file##*/}
    case ${name,,} in *.part|*.crdownload|*.tmp|*.download|*.aria2) continue ;; esac

    if [[ $name == *.* ]]; then ext=${name##*.}; ext=${ext,,}; else ext=""; fi
    dest=""
    [[ -n $ext ]] && dest=${MAP[$ext]:-}

    if [[ -z $dest ]]; then
        unknown[${ext:-"(без расширения)"}]=$(( ${unknown[${ext:-"(без расширения)"}]:-0} + 1 ))
        continue
    fi

    if $DRY; then
        printf '  [dry] %s -> %s/\n' "$name" "${dest/#$HOME/\~}"
        moved=$((moved + 1))
        continue
    fi

    mkdir -p "$dest"
    target=$(unique_path "$dest" "$name")
    if mv -n -- "$file" "$target"; then
        printf '  ✓ %s -> %s/\n' "$name" "${dest/#$HOME/\~}"
        echo "[$(date '+%F %T')] $file -> $target" >> "$LOG_FILE"
        moved=$((moved + 1))
    else
        printf '  ✗ не удалось переместить: %s\n' "$name" >&2
        failed=$((failed + 1))
    fi
done < <(find "$SRC_DIR" -maxdepth 1 -type f ! -name '.*' -mmin +"$MIN_AGE" -print0)

echo "----------------------------------------"
if $DRY; then echo "Показ: было бы перемещено $moved. Запусти без -n."; else echo "Перемещено: $moved$( ((failed)) && echo ", ошибок: $failed" )"; fi
if (( ${#unknown[@]} > 0 )); then
    printf 'Остались (тип неизвестен):'
    for e in "${!unknown[@]}"; do printf ' %s×%s' "$e" "${unknown[$e]}"; done; echo
fi

# Если запущено не из терминала (по таймеру) — короткое уведомление
if ! $DRY && (( moved > 0 )) && [[ ! -t 1 ]] && command -v notify-send >/dev/null; then
    notify-send -a organize "Загрузки отсортированы" "Перемещено файлов: $moved"
fi
[[ $failed -eq 0 ]]

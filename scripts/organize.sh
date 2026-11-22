#!/usr/bin/env bash
# organize.sh — раскладывает файлы из ~/data/downloads по папкам.
#
#   organize.sh            — разложить (свежие файлы тоже; качающиеся пропускаются)
#   organize.sh -n         — только показать, что будет перемещено
#   organize.sh --age N    — дополнительно не трогать файлы младше N минут (по умолчанию 0)
#
# Защита от недокачанных: пропускаются файлы, которые сейчас открыты каким-то процессом
# (fuser/lsof), у которых за 2 секунды изменился размер или время, а также *.part,
# *.crdownload, *.tmp и т.п. Подпапки не трогаются.
# Файлы неизвестных типов остаются на месте, но скрипт их перечислит в конце.
set -uo pipefail          # без -e: одна ошибка не должна обрывать сортировку остальных

SRC_DIR="$HOME/data/downloads"
LOG_FILE="$HOME/.local/share/organize.log"
MIN_AGE=0                 # минут: 0 = не смотреть на возраст (защита от «ещё качается» — ниже, по факту)

DIR_PICS="$HOME/data/media/pictures"
DIR_VIDS="$HOME/data/media/videos"
DIR_MUSIC="$HOME/data/media/music"
DIR_DOCS="$HOME/data/docs"
DIR_ARCH="$HOME/data/archives"
DIR_CODE="$HOME/data/dev/scripts"
DIR_INST="$HOME/data/tools/installers"

# --- расписания (проверяются раньше обычной сортировки по расширению) ---------
SCHEDULE_DIR="$DIR_DOCS/расписание"
SCHEDULE_NAME_RE='raspisanie|zanyati|posle[ _-]*smeny|do[ _-]*smeny|расписани'   # по имени файла, без учёта регистра
MY_GROUP_RE='ivt[ _-]*25[ _-]*1b'                                                # моя группа (допускает пробелы/дефисы)
MY_SCHEDULE_NAME="расписание"                                                    # файл группы станет расписание.<ext>

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
while (( $# > 0 )); do
    a=$1; shift
    case $a in
        -n|--dry-run) DRY=true ;;
        --now)        MIN_AGE=0 ;;                       # оставлено для совместимости
        --age)        MIN_AGE=${1:-0}; shift ;;
        -h|--help)    sed -n '2,11p' "$0"; exit 0 ;;
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

mvlog() {   # <откуда> <куда> — перемещение с записью в лог
    if mv -n -- "$1" "$2"; then
        echo "[$(date '+%F %T')] $1 -> $2" >> "$LOG_FILE"; return 0
    fi
    return 1
}
pretty() { local p=${1/#$HOME/\~}; echo "$p"; }

handle_schedule() {   # <полный путь> <имя файла>
    local file=$1 name=$2 lname=${2,,} ext="" target old n=1
    [[ $name == *.* ]] && ext=".${name##*.}" && ext=${ext,,}

    if [[ $lname =~ $MY_GROUP_RE ]]; then
        target="$SCHEDULE_DIR/$MY_SCHEDULE_NAME$ext"
        if [[ -e $target ]]; then
            if cmp -s -- "$file" "$target"; then               # точно такой же файл уже есть
                if $DRY; then printf '  [dry] %s — дубликат, будет удалён\n' "$name"
                else rm -- "$file" && printf '  ≡ %s — такой же уже есть, дубликат удалён\n' "$name"
                     echo "[$(date '+%F %T')] duplicate removed: $file" >> "$LOG_FILE"; fi
                return 0
            fi
            while [[ -e "$SCHEDULE_DIR/${MY_SCHEDULE_NAME}_старое_$n$ext" ]]; do n=$((n + 1)); done
            old="$SCHEDULE_DIR/${MY_SCHEDULE_NAME}_старое_$n$ext"
            if $DRY; then printf '  [dry] %s -> %s\n' "${target##*/}" "${old##*/}"
            else mvlog "$target" "$old" || { printf '  ✗ не удалось переименовать старое: %s\n' "${target##*/}" >&2; failed=$((failed + 1)); return 0; }
                 printf '  ↻ %s -> %s\n' "${target##*/}" "${old##*/}"; fi
        fi
        if $DRY; then printf '  [dry] %s -> %s\n' "$name" "$(pretty "$target")"
        else mkdir -p "$SCHEDULE_DIR"
             if mvlog "$file" "$target"; then printf '  ✓ %s -> %s\n' "$name" "$(pretty "$target")"
             else printf '  ✗ не удалось переместить: %s\n' "$name" >&2; failed=$((failed + 1)); return 0; fi; fi
    else
        target=$(unique_path "$SCHEDULE_DIR" "$name")           # чужие расписания — с исходным именем
        if $DRY; then printf '  [dry] %s -> %s/\n' "$name" "$(pretty "$SCHEDULE_DIR")"
        else mkdir -p "$SCHEDULE_DIR"
             if mvlog "$file" "$target"; then printf '  ✓ %s -> %s/\n' "$name" "$(pretty "$SCHEDULE_DIR")"
             else printf '  ✗ не удалось переместить: %s\n' "$name" >&2; failed=$((failed + 1)); return 0; fi; fi
    fi
    moved=$((moved + 1))
}

in_use() {   # файл сейчас открыт каким-то процессом?
    if command -v fuser >/dev/null; then fuser -s -- "$1" 2>/dev/null
    elif command -v lsof >/dev/null; then lsof -- "$1" >/dev/null 2>&1
    else return 1; fi
}
sig() { stat -c '%s %Y' -- "$1" 2>/dev/null; }   # размер + время изменения

age_args=(); (( MIN_AGE > 0 )) && age_args=(-mmin +"$MIN_AGE")
mapfile -d '' recs < <(find "$SRC_DIR" -maxdepth 1 -type f ! -name '.*' "${age_args[@]}" -printf '%T@ %p\0' | sort -z -n)

declare -A snap=()
for rec in "${recs[@]}"; do f=${rec#* }; snap[$f]=$(sig "$f"); done
(( ${#recs[@]} > 0 )) && sleep 2                      # если файл растёт — размер за это время изменится
command -v fuser >/dev/null || command -v lsof >/dev/null || \
    echo "ℹ️  нет fuser/lsof (pacman -S psmisc) — проверка «файл открыт» отключена, только по размеру"
busy=()

for rec in "${recs[@]}"; do        # от старых к новым: самый свежий станет «текущим»
    file=${rec#* }
    name=${file##*/}
    case ${name,,} in *.part|*.crdownload|*.tmp|*.download|*.aria2|*.!qb|*.td) continue ;; esac
    if [[ $(sig "$file") != "${snap[$file]}" ]] || in_use "$file"; then busy+=("$name"); continue; fi

    if [[ ${name,,} =~ $SCHEDULE_NAME_RE ]]; then handle_schedule "$file" "$name"; continue; fi

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
done

echo "----------------------------------------"
if $DRY; then echo "Показ: было бы перемещено $moved. Запусти без -n."; else echo "Перемещено: $moved$( ((failed)) && echo ", ошибок: $failed" )"; fi
if (( ${#busy[@]} > 0 )); then
    echo "Пропущены (сейчас качаются или открыты): ${busy[*]}"
fi
if (( ${#unknown[@]} > 0 )); then
    printf 'Остались (тип неизвестен):'
    for e in "${!unknown[@]}"; do printf ' %s×%s' "$e" "${unknown[$e]}"; done; echo
fi

# Если запущено не из терминала (по таймеру) — короткое уведомление
if ! $DRY && (( moved > 0 )) && [[ ! -t 1 ]] && command -v notify-send >/dev/null; then
    notify-send -a organize "Загрузки отсортированы" "Перемещено файлов: $moved"
fi
[[ $failed -eq 0 ]]

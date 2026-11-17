# ~/.bashrc — порт с fish (CachyOS + Hyprland)

# Только для интерактивных шеллов
[[ $- != *i* ]] && return

# --- CachyOS-конфиг bash (если установлен) ----------------------------------
for f in /usr/share/cachyos-bash-config/cachyos-config.bash \
         /usr/share/cachyos-bash-config/bashrc; do
    [[ -f $f ]] && { source "$f"; break; }
done

# --- История ----------------------------------------------------------------
HISTSIZE=50000
HISTFILESIZE=100000
HISTCONTROL=ignoreboth:erasedups
shopt -s histappend checkwinsize cmdhist autocd cdspell globstar 2>/dev/null
PROMPT_COMMAND="history -a${PROMPT_COMMAND:+; $PROMPT_COMMAND}"

# --- Алиасы -----------------------------------------------------------------
alias ls='ls --color=auto'
alias ll='ls -lah --color=auto'
alias grep='grep --color=auto'
alias ..='cd ..'
alias ...='cd ../..'

# --- Промпт / утилиты -------------------------------------------------------
if command -v starship >/dev/null; then
    eval "$(starship init bash)"
else
    PS1='\[\e[1;35m\]\u\[\e[0m\]@\h \[\e[1;34m\]\w\[\e[0m\]\n\$ '
fi
command -v zoxide >/dev/null && eval "$(zoxide init bash)"
[[ -f /usr/share/fzf/key-bindings.bash ]] && source /usr/share/fzf/key-bindings.bash
[[ -f /usr/share/fzf/completion.bash ]]   && source /usr/share/fzf/completion.bash

# --- Простые функции --------------------------------------------------------
copy() { wl-copy; }

discord-proxy() { sudo ~/data/tools/zapret-discord-youtube-linux/service.sh; }

v2rayN() {
    nohup /home/zento/data/tools/v2rayN-linux-64/v2rayN "$@" >/dev/null 2>&1 &
}

# nh <команда...> — запуск в фоне с логом
nh() {
    if (( $# == 0 )); then echo "❌ Использование: nh <команда> [аргументы...]"; return 1; fi
    local log_dir=~/.local/share/nh log_file
    mkdir -p "$log_dir"
    log_file="$log_dir/$(basename "$1")-$(date +%Y-%m-%d_%H-%M-%S).log"
    echo "🚀 Запускаю: $*"
    echo "📄 Лог: $log_file"
    nohup "$@" >"$log_file" 2>&1 &
    echo "✅ PID: $!"
}

# swap <файл1> <файл2>
swap() {
    local f1=$1 f2=$2 tmp
    if [[ -z $f1 || -z $f2 ]]; then echo "❌ Использование: swap <файл1> <файл2>"; return 1; fi
    if [[ ! -f $f1 && ! -f $f2 ]]; then echo "❌ Ни один из файлов не существует: $f1, $f2"; return 1; fi
    [[ -f $f1 ]] || { echo "⚠️  $f1 не существует, создаю пустой"; touch "$f1"; }
    [[ -f $f2 ]] || { echo "⚠️  $f2 не существует, создаю пустой"; touch "$f2"; }
    tmp=$(mktemp)
    cp "$f1" "$tmp" && cp "$f2" "$f1" && cp "$tmp" "$f2"
    rm -f "$tmp"
    echo "✅ Свапнуто: $f1 ↔ $f2"
}

# mark / jump (тот же файл меток, что и в fish)
_MARKS_FILE=~/.config/fish/marks

mark() {
    if [[ -z $1 ]]; then echo "❌ Использование: mark <имя>"; return 1; fi
    mkdir -p "$(dirname "$_MARKS_FILE")"
    if [[ -f $_MARKS_FILE ]]; then
        grep -v "^$1 " "$_MARKS_FILE" > "$_MARKS_FILE.tmp"
        mv "$_MARKS_FILE.tmp" "$_MARKS_FILE"
    fi
    echo "$1 $PWD" >> "$_MARKS_FILE"
    echo "📍 Сохранено '$1' → $PWD"
}

jump() {
    if [[ -z $1 ]]; then
        echo "❌ Использование: jump <имя>"
        echo "Доступные метки:"
        [[ -f $_MARKS_FILE ]] && cut -d' ' -f1 "$_MARKS_FILE" | sort -u | sed 's/^/  /'
        return 1
    fi
    if [[ ! -f $_MARKS_FILE ]]; then echo "❌ Нет сохранённых меток. Используй: mark <имя>"; return 1; fi
    local p
    p=$(grep "^$1 " "$_MARKS_FILE" | head -1 | cut -d' ' -f2-)
    if [[ -n $p ]]; then
        cd "$p" && echo "🚀 Перешли в '$p'"
    else
        echo "❌ Метка '$1' не найдена"; return 1
    fi
}
_jump_complete() {
    COMPREPLY=( $(compgen -W "$(cut -d' ' -f1 "$_MARKS_FILE" 2>/dev/null)" -- "${COMP_WORDS[COMP_CWORD]}") )
}
complete -F _jump_complete jump

# show <расширение> [папка]
show() {
    local ext=$1 target=${2:-.}
    if [[ -z $ext ]]; then echo "❌ Укажи расширение, например: show txt"; return 1; fi
    find "$target" -type f -name "*.$ext" \
        ! -path "*/micro/buffers/*" ! -path "*/micro/backups/*" \
        ! -name "*.db" ! -name "*.sqlite" ! -name "*.bin" ! -name "*.so" \
        ! -name "*.dll" ! -name "*.o" ! -name "*.exe" \
        -exec echo "=== {} ===" \; -exec cat {} \;
}

# showall [пути...] — содержимое всех текстовых файлов (с защитой секретов)
showall() {
    (( $# == 0 )) && set -- .
    local t
    for t in "$@"; do
        if [[ -e $t ]]; then
            echo "=== Папка: $t ==="
            find "$t" -type f \
                ! -iname "*.png" ! -iname "*.jpg" ! -iname "*.jpeg" ! -iname "*.gif" \
                ! -iname "*.webp" ! -iname "*.ico" ! -iname "*.svg" ! -iname "*.ttf" \
                ! -iname "*.otf" ! -iname "*.woff" ! -iname "*.woff2" ! -iname "*.mp3" \
                ! -iname "*.mp4" ! -iname "*.webm" ! -iname "*.avi" ! -iname "*.mkv" \
                ! -iname "*.pdf" ! -iname "*.zip" ! -iname "*.gz" ! -iname "*.tar" \
                ! -iname "*.xz" ! -iname "*.db" ! -iname "*.sqlite" ! -iname "*.so" \
                ! -iname "*.dll" ! -iname "*.o" ! -iname "*.exe" ! -iname "*.bin" \
                ! -path "*/completions/*" ! -path "*/fish_variables" ! -path "*/.git/*" \
                ! -path "*/.cache/*" ! -path "*/.ssh/*" ! -path "*/.gnupg/*" \
                ! -path "*/.aws/*" ! -path "*/.kube/*" ! -path "*/.docker/*" \
                ! -path "*/.config/gh/*" ! -path "*/.mozilla/*" ! -path "*/node_modules/*" \
                ! -path "*/venv/*" ! -path "*/.venv/*" ! -path "*/Cookies*" \
                ! -name ".env" ! -name ".env.*" ! -name "*.env" ! -name "id_rsa*" \
                ! -name "id_ed25519*" ! -name "*.pem" ! -name "*.key" ! -name "*.p12" \
                ! -name "*.pfx" ! -name "*.kdbx" ! -name "credentials*" ! -name "token*" \
                ! -name "*.secret" \
                -exec echo "=== {} ===" \; -exec cat {} \;
        else
            echo "❌ $t не существует"
        fi
    done
}

# --- Большие интерактивные скрипты: пока запускаются через fish ------------
# (когда решите окончательно уйти с fish — их можно портировать на bash)
_fish_fn() { # _fish_fn <файл> <функция> [аргументы...]
    local file=$1 fn=$2; shift 2
    fish -c "source ~/.config/fish/functions/$file; $fn \$argv" -- "$@"
}
cleanup() { _fish_fn cleanup.fish cleanup "$@"; }
imgc()    { _fish_fn imgc.fish    imgc    "$@"; }
ytdl()    { _fish_fn ytdl.fish    ytdl    "$@"; }
netmode() { _fish_fn netmode.fish netmode "$@"; }

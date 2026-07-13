source /usr/share/cachyos-fish-config/cachyos-config.fish

# Отключаем fastfetch
function fish_greeting
end

function copy
    wl-copy
end

alias b "bash"
alias m "micro"

set -gx PATH $PATH ~/.local/bin

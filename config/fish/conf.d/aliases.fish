
alias b "bash"
alias m "micro"
alias g "git"
alias n "nvim"
alias yz "yazi"


alias dots "cd ~/data/dotfiles"
alias labs "cd ~/data/dev/LABS"
alias config "cd ~/.config/"


alias syslog_emerg "sudo dmesg --level=emerg,alert,crit"
alias syslog "sudo dmesg --level=err,warn"
alias du-sort "du -sh * | sort -h"
alias foldersize "du -sh"
alias sz "du -sh"
alias upd "sudo pacman -Syu"


abbr --add --command sudo b bash
abbr --add --command sudo m micro
abbr --add --command sudo g git
abbr --add --command sudo n nvim
abbr --add --command sudo yz yazi
abbr --add --command sudo foldersize 'du -sh'
abbr --add --command sudo sz 'du -sh'
abbr --add --command sudo yt1080 "yt-dlp -f 'bestvideo[height<=1080]+bestaudio/best' --merge-output-format mp4"
abbr --add --command sudo ff '~/.config/fastfetch/noctalia-fastfetch'
abbr --add --command sudo zapret './data/tools/zapret-discord-youtube-linux/service.sh'

alias yt1080 "yt-dlp -f 'bestvideo[height<=1080]+bestaudio/best' --merge-output-format mp4"
alias ff "~/.config/fastfetch/noctalia-fastfetch"
alias zapret "./data/tools/zapret-discord-youtube-linux/service.sh"

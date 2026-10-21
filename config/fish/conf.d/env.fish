set -gx EDITOR micro
set -gx VISUAL micro
set -gx BROWSER zen-browser
set -gx PATH $PATH ~/.local/bin
set -gx PATH $PATH ~/data/dotfiles/scripts

set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH

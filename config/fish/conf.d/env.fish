set -gx EDITOR micro
set -gx VISUAL micro
set -gx BROWSER zen-browser

set -gx BUN_INSTALL "$HOME/.bun"

# fish_add_path автоматически проверит на дубликаты
fish_add_path "$BUN_INSTALL/bin"
fish_add_path ~/data/dotfiles/scripts
fish_add_path ~/.local/bin

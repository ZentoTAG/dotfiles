#!/usr/bin/env bash
# ~/data/dotfiles/scripts/diskreport.sh
out=~/diskreport.txt
{
echo "== df (только реальные ФС) =="
df -hT -x tmpfs -x devtmpfs -x efivarfs

echo; echo "== Топ-25 в / (-x = не выходить за пределы этой ФС, HDD не трогаем) =="
sudo du -xh --max-depth=2 / 2>/dev/null | sort -rh | head -25

echo; echo "== Топ-25 в \$HOME =="
du -xh --max-depth=2 ~ 2>/dev/null | sort -rh | head -25

echo; echo "== Кэши и логи =="
du -sh ~/.cache ~/.local/share ~/.var 2>/dev/null
du -sh /var/cache/pacman/pkg /var/log 2>/dev/null
journalctl --disk-usage

echo; echo "== Топ-30 пакетов по размеру =="
expac -H M '%m\t%n' | sort -rh | head -30

echo; echo "== Явно установленные, не из репо (AUR) =="
pacman -Qqem

echo; echo "== Файлы >500M в \$HOME =="
find ~ -xdev -type f -size +500M -printf '%s\t%p\n' 2>/dev/null | sort -rn | head -20 | numfmt --to=iec --field=1
} > "$out"
wc -c "$out"

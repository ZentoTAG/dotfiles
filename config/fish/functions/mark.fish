function mark --description "Сохранить текущий путь под именем"
    set -l file ~/.config/fish/marks

    if test -z "$argv[1]"
        echo "❌ Использование: mark <имя>"
        return 1
    end

    if test -f $file
        grep -v "^$argv[1] " $file > $file.tmp 2>/dev/null
        mv $file.tmp $file
    end

    echo "$argv[1] "(pwd) >> $file
    echo "📍 Сохранено '$argv[1]' → "(pwd)
end

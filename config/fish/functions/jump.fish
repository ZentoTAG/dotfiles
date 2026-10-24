function jump --description "Перейти к сохранённому пути"
    set -l file ~/.config/fish/marks

    if test -z "$argv[1]"
        echo "❌ Использование: jump <имя>"
        echo "Доступные метки:"
        if test -f $file
            cut -d' ' -f1 $file | sort -u | sed 's/^/  /'
        end
        return 1
    end

    if not test -f $file
        echo "❌ Нет сохранённых меток. Используй: mark <имя>"
        return 1
    end

    set -l path (grep "^$argv[1] " $file | head -1 | cut -d' ' -f2-)

    if test -n "$path"
        cd $path
        echo "🚀 Перешли в '$path'"
    else
        echo "❌ Метка '$argv[1]' не найдена"
        return 1
    end
end

complete -c jump -f -a "(cut -d' ' -f1 ~/.config/fish/marks 2>/dev/null)"

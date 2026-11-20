function ff-logo --description 'Выбрать рисунок Fastfetch'
    set -l dir "$HOME/.config/fastfetch/ascii"
    set -l active "$dir/active.txt"
    set -l files
    for file in "$dir"/*.txt
        test "$file" = "$active"; and continue
        test -f "$file"; and set -a files "$file"
    end

    if test (count $files) -eq 0
        echo "Нет рисунков .txt в $dir" >&2
        return 1
    end

    if test (count $argv) -gt 1
        echo 'Использование: ff-logo [имя | list]' >&2
        return 1
    end

    set -l selected
    if test (count $argv) -eq 0; or test "$argv[1]" = list
        set -l current (readlink "$active" 2>/dev/null)
        for i in (seq (count $files))
            set -l name (path basename "$files[$i]")
            set -l marker ' '
            test "$name" = "$current"; and set marker '*'
            set -l size (wc -L < "$files[$i]" | string trim)
            set -l height (awk 'END {print NR}' "$files[$i]")
            printf '%s %2d. %-20s %s×%s\n' "$marker" "$i" (string replace -r '\.txt$' '' "$name") "$size" "$height"
        end
        test (count $argv) -gt 0; and return 0
        read -l -P 'Номер рисунка (Enter — отмена): ' choice
        test -z "$choice"; and return 0
        if not string match -rq '^[0-9]+$' -- "$choice"; or test "$choice" -lt 1; or test "$choice" -gt (count $files)
            echo 'Неверный номер рисунка.' >&2
            return 1
        end
        set selected "$files[$choice]"
    else
        set -l name (string replace -r '\.txt$' '' -- "$argv[1]")
        for file in $files
            if test (path basename "$file") = "$name.txt"
                set selected "$file"
                break
            end
        end
        if test -z "$selected"
            echo "Рисунок не найден: $argv[1]. Список: ff-logo list" >&2
            return 1
        end
    end

    if test -e "$active"; and not test -L "$active"
        echo "Не могу заменить обычный файл $active" >&2
        return 1
    end
    ln -sfn -- (path basename "$selected") "$active"; or return 1
    echo "Выбран рисунок: "(path basename "$selected")
    "$HOME/.config/fastfetch/noctalia-fastfetch"
end

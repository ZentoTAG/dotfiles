function swap
    set -l file1 $argv[1]
    set -l file2 $argv[2]

    if test -z "$file1" -o -z "$file2"
        echo "❌ Использование: swap <файл1> <файл2>"
        return 1
    end

    # Проверяем существование файлов
    set -l f1_exists 0
    set -l f2_exists 0
    test -f "$file1"; and set f1_exists 1
    test -f "$file2"; and set f2_exists 1

    if test $f1_exists -eq 0; and test $f2_exists -eq 0
        echo "❌ Ни один из файлов не существует: $file1, $file2"
        return 1
    end

    # Если один не существует — создаём пустой
    if test $f1_exists -eq 0
        echo "⚠️  $file1 не существует, создаю пустой"
        touch "$file1"
    end
    if test $f2_exists -eq 0
        echo "⚠️  $file2 не существует, создаю пустой"
        touch "$file2"
    end

    # Меняем местами через временный файл
    set -l tmp (mktemp)
    cp "$file1" "$tmp"
    cp "$file2" "$file1"
    cp "$tmp" "$file2"
    rm "$tmp"

    echo "✅ Свапнуто: $file1 ↔ $file2"
end

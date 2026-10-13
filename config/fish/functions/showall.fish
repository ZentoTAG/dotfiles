function showall --description "Показать содержимое всех текстовых файлов"
    if test (count $argv) -eq 0
        set argv .
    end

    for target in $argv
        if test -e "$target"
            echo "=== Папка: $target ==="
            find "$target" -type f \
                ! -name "*.png" \
                ! -name "*.jpg" \
                ! -name "*.jpeg" \
                ! -name "*.gif" \
                ! -name "*.webp" \
                ! -name "*.ico" \
                ! -name "*.svg" \
                ! -name "*.ttf" \
                ! -name "*.otf" \
                ! -name "*.woff" \
                ! -name "*.woff2" \
                ! -name "*.mp3" \
                ! -name "*.mp4" \
                ! -name "*.webm" \
                ! -name "*.avi" \
                ! -name "*.mkv" \
                ! -name "*.pdf" \
                ! -name "*.zip" \
                ! -name "*.gz" \
                ! -name "*.tar" \
                ! -name "*.xz" \
                ! -name "*.db" \
                ! -name "*.sqlite" \
                ! -name "*.so" \
                ! -name "*.dll" \
                ! -name "*.o" \
                ! -name "*.exe" \
                ! -name "*.bin" \
                ! -path "*/completions/*" \
                ! -path "*/fish_variables" \
                -exec echo "=== {} ===" \; -exec cat {} \;
        else
            echo "❌ $target не существует"
        end
    end
end

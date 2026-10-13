function show --description "Показать содержимое файлов с указанным расширением"
    set ext $argv[1]
    set target $argv[2]

    if test -z "$ext"
        echo "❌ Укажи расширение, например: show txt"
        return 1
    end

    if test -z "$target"
        set target .
    end

    find $target -type f -name "*.$ext" \
        ! -path "*/micro/buffers/*" \
        ! -path "*/micro/backups/*" \
        ! -name "*.db" \
        ! -name "*.sqlite" \
        ! -name "*.bin" \
        ! -name "*.so" \
        ! -name "*.dll" \
        ! -name "*.o" \
        ! -name "*.exe" \
        -exec echo "=== {} ===" \; -exec cat {} \;
end

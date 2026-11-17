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
                ! -path "*/.git/*" \
                ! -path "*/.cache/*" \
                ! -path "*/.ssh/*" \
                ! -path "*/.gnupg/*" \
                ! -path "*/.aws/*" \
                ! -path "*/.kube/*" \
                ! -path "*/.docker/*" \
                ! -path "*/.config/gh/*" \
                ! -path "*/.mozilla/*" \
                ! -path "*/node_modules/*" \
                ! -path "*/venv/*" \
                ! -path "*/.venv/*" \
                ! -path "*/Cookies*" \
                ! -name ".env" \
                ! -name ".env.*" \
                ! -name "*.env" \
                ! -name "id_rsa*" \
                ! -name "id_ed25519*" \
                ! -name "*.pem" \
                ! -name "*.key" \
                ! -name "*.p12" \
                ! -name "*.pfx" \
                ! -name "*.kdbx" \
                ! -name "credentials*" \
                ! -name "token*" \
                ! -name "*.secret" \
                -exec echo "=== {} ===" \; -exec cat {} \;
        else
            echo "❌ $target не существует"
        end
    end
end

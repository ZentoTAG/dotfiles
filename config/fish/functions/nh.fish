function nh --description "Запустить программу в фоне (nohup)"
    if test (count $argv) -eq 0
        echo "❌ Использование: nh <команда> [аргументы...]"
        return 1
    end

    # Создаем папку для логов, если ее нет
    set -l log_dir ~/.local/share/nh
    mkdir -p $log_dir

    # Имя лог-файла (по имени программы и дате)
    set -l prog_name (basename $argv[1])
    set -l timestamp (date +%Y-%m-%d_%H-%M-%S)
    set -l log_file "$log_dir/$prog_name-$timestamp.log"

    echo "🚀 Запускаю: $argv"
    echo "📄 Лог: $log_file"

    # Запускаем через nohup в фоне
    # > $log_file 2>&1 — перенаправляем и stdout, и stderr в файл
    # & — отправляем в фон
    nohup $argv > $log_file 2>&1 &

    # Показываем PID запущенного процесса
    set -l pid $last_pid
    echo "✅ PID: $pid"
end

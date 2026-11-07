-- Основной монитор на ПК
hl.monitor({
    output = "DP-1",
    mode = "1920x1080@180",
    position = "0x0",
    scale = 1,
})

-- Всё остальное (экран ноутбука, любой новый монитор):
-- родное разрешение, новый монитор встаёт справа
hl.monitor({
    output = "",
    mode = "preferred",
    position = "auto",
    scale = 1,
})

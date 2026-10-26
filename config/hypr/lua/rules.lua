-- ============================================================
-- WINDOW RULES
-- ============================================================

hl.window_rule({
    name = "v2rayN-workspace",
    match = { class = ".*v2rayN.*" },
    workspace = 9,
    no_initial_focus = true,
})

hl.window_rule({
    match = { class = "^(kitty)$" },
    tile = true,
    float = false
})

hl.window_rule({
    name = "steam-workspace",
    match = { class = ".*[sS]team.*" },
    workspace = 3,
    no_initial_focus = true,
})

hl.window_rule({
    name = "steam-app-workspace",
    match = { class = ".*steam_app_3143298597.*" },
    workspace = 4,
    no_initial_focus = true,
})

hl.window_rule({
    name = "genshin-workspace",
    match = { title = ".*Genshin Impact.*" },
    workspace = 4,
    no_initial_focus = true,
})

hl.window_rule({
    name = "hoyoplay-workspace",
    match = { title = ".*HoYoPlay.*" },
    workspace = 4,
    no_initial_focus = true,
})

-- ============================================================
-- ПРИЛОЖЕНИЯ ПО РАБОЧИМ СТОЛАМ (ручной запуск)
-- ============================================================

-- Браузер — рабочий стол 1
hl.window_rule({
    name = "zen-workspace",
    match = { class = "^(zen)$" },
    workspace = 1,
})

-- Telegram / AyuGram — рабочий стол 2, полноразмерная колонка
hl.window_rule({
    name = "telegram-workspace",
    match = { class = "^(com\\.ayugram\\.desktop|AyuGram|org\\.telegram\\.desktop)$" },
    workspace = 2,
    scrolling_width = 1.0,
})

-- Discord — рабочий стол 2, полноразмерная колонка справа от Telegram
hl.window_rule({
    name = "discord-workspace",
    match = { class = "^(discord|vesktop|com\\.discordapp\\.Discord)$" },
    workspace = 2,
    scrolling_width = 1.0,
})

-- Правило для слоя выделения (отключает анимации)
hl.layer_rule({
    match = { namespace = "selection" },
    no_anim = true,
})

-- ============================================================
-- WINAPPS FIX
-- ============================================================

hl.window_rule({
    name = "winapps-microsoft",
    match = {
        class = ".*Microsoft.*",
    },
    float = true,
    no_anim = true,
})

hl.window_rule({
    name = "winapps-suppress-maximize",
    match = {
        class = ".*Microsoft.*",
    },
    suppress_event = "maximize",
})

-- ============================================================
-- ИГРОВЫЕ ПРАВИЛА (максимальная производительность)
-- ============================================================

-- Все игровые окна (Steam, Proton, Wine)
-- Убираем анимации, границы и скругление
hl.window_rule({
    name = "game-optimization",
    match = {
        class = ".*steam_app_.*",
    },
    no_anim = true,
    border_size = 0,
    rounding = 0,
})

-- Proton игры
hl.window_rule({
    name = "game-proton-optimization",
    match = {
        class = ".*proton.*",
    },
    no_anim = true,
    border_size = 0,
    rounding = 0,
})

-- Wine игры
hl.window_rule({
    name = "game-wine-optimization",
    match = {
        class = ".*wine.*",
    },
    no_anim = true,
    border_size = 0,
    rounding = 0,
})

-- Genshin Impact (особое правило)
hl.window_rule({
    name = "genshin-performance",
    match = {
        title = ".*Genshin Impact.*",
    },
    no_anim = true,
    border_size = 0,
    rounding = 0,
    fullscreen = true,
})

hl.window_rule({
    match = { 
        class = "zoom", 
        initial_title = "annotate_toolbar" 
    },
    float = true,
    no_focus = true,
    no_anim = true,
    no_blur = true,
    move = "100%-20 100%-20"  -- сдвигает окно за пределы экрана
})

-- PrismLauncher на workspace 3
hl.window_rule({
    name = "prismlauncher-workspace",
    match = { class = "org\\.prismlauncher\\.PrismLauncher" },
    workspace = 3,
    no_initial_focus = true,
})

-- Minecraft на workspace 3
hl.window_rule({
    name = "minecraft-workspace",
    match = { class = "com\\.mojang\\.minecraft" },
    workspace = 3,
    no_initial_focus = true,
})
-- 1. Принудительно отправляем диалоговые окна переименования во float по их стартовому заголовку
hl.window_rule({
    name = "thunar-rename-float",
    match = { 
        class = "^(thunar)$", 
        initial_title = "^(Переименовать.*|Rename.*|Массовое переименование.*|Bulk Rename.*)$" 
    },
    float = true,
    center = true,
})

-- 2. Возвращаем основное окно Thunar в тайлинг (отменяем float)
hl.window_rule({
    name = "thunar-main-tile",
    match = { 
        class = "^(thunar)$", 
        initial_title = ".*Thunar$" -- Совпадает с вашим "zento - Thunar"
    },
    float = false,
})

hl.window_rule({
    name = "kitty-float",
    match = { class = "kitty-float" },
    float = true,
    center = true,
    size = "800 600", -- размер окна (можно подогнать)
})

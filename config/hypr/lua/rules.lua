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

hl.window_rule({
    name = "waypaper-float",
    match = { class = "waypaper" },
    float = true,
    center = true,
})

-- Правило для слоя выделения (отключает анимации)
hl.layer_rule({
    match = { namespace = "selection" },
    no_anim = true,
})

-- ============================================================
-- WINAPPS FIX (чтобы окна не прыгали и не телепортировались)
-- ============================================================
-- 
-- hl.window_rule({
--     name = "winapps-access",
--     match = { class = "Microsoft Access" },
--     float = true,
--     center = true,
-- })
-- 
-- hl.window_rule({
--     name = "winapps-generic",
--     match = { class = ".*Microsoft.*" },
--     float = true,
-- })
-- 
-- -- Добавь это правило к остальным для WinApps
-- hl.window_rule({
--     name = "winapps-suppress-maximize",
--     match = { class = ".*Microsoft.*" },
--     suppress_event = "maximize",  -- Отключает полный экран при наведении
-- })

-- Microsoft Access / WinApps
hl.window_rule({
    name = "winapps-microsoft",
    match = {
        class = ".*Microsoft.*",
    },
    float = true,
    no_anim = true,
})

-- Игнорировать maximize-запросы RemoteApp
hl.window_rule({
    name = "winapps-suppress-maximize",
    match = {
        class = ".*Microsoft.*",
    },
    suppress_event = "maximize",
})

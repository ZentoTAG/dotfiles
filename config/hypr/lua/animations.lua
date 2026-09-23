-- ============================================================
-- ANIMATIONS
-- ============================================================

-- Кастомные кривые
hl.curve("fast", { type = "bezier", points = {{0.05, 0.9}, {0.1, 1.0}} })
hl.curve("overshot", { type = "bezier", points = {{0.13, 0.99}, {0.29, 1.1}} })
hl.curve("wind", { type = "bezier", points = {{0.00, 0.06}, {0.00, 1.03}} })
hl.curve("easeOutQuart", { type = "bezier", points = {{0.25, 1}, {0.5, 1}} })

-- Анимации (у каждой указан bezier)
hl.animation({ leaf = "global", enabled = true, speed = 10, bezier = "fast" })
hl.animation({ leaf = "windows", enabled = true, speed = 2, bezier = "fast", style = "popin" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 3, bezier = "easeOutQuart", style = "slide" })
hl.animation({ leaf = "layers", enabled = true, speed = 1, bezier = "fast", style = "popin" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 2, bezier = "wind", style = "slide" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 4, bezier = "easeOutQuart" })

hl.config({
    misc = { animate_manual_resizes = true },
    dwindle = { preserve_split = true, force_split = 2 },
})

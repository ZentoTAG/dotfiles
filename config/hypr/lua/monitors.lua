-- Второй монитор (HDMI-A-2) — СЛЕВА
hl.monitor({
    output = "HDMI-A-2",
    mode = "1366x768@59.79",
    position = "0x0",
    scale = 1,
})

-- Основной монитор (DP-1) — СПРАВА от HDMI
hl.monitor({
    output = "DP-1",
    mode = "1920x1080@180",
    position = "1366x0",
    scale = 1,
})
hl.monitor({
    output = "",
    mode = "preferred",
    position = "auto",
    scale = 1,
})

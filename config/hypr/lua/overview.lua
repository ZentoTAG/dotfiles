-- scrolloverview: обзор в стиле niri
hl.on("config.reloaded", function()
    -- при старте плагин ещё не загружен, пропускаем
    if not (hl.plugin and hl.plugin.scrolloverview) then return end

    hl.config({
        plugin = {
            scrolloverview = {
                gesture_distance = 300,
                scale = 0.5,
                workspace_gap = 0,
            },
        },
    })

    hl.plugin.scrolloverview.gesture({ fingers = 3, direction = "vertical" })
end)

hl.bind("SUPER + O", function()
    hl.plugin.scrolloverview.overview("toggle")
end)

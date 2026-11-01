-- Hyprspace: обзор воркспейсов
hl.config({
    plugin = {
        overview = {
            panelColor = "#11131a",
            panelBorderColor = "#adc6ff",
            workspaceActiveBorder = "#adc6ff",
            onBottom = false,
            autoDrag = true,
            showNewWorkspace = true,
        },
    },
})

hl.bind("SUPER + O", function()
    if hl.plugin and hl.plugin.overview then
        hl.plugin.overview.toggle()
    end
end, { description = "Обзор воркспейсов (Hyprspace)" })

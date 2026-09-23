VERSION = "1.2.0"

local micro = import("micro")
local config = import("micro/config")
local shell = import("micro/shell")

function init()
    config.MakeCommand("copy", copy, config.NoComplete)
    config.MakeCommand("cut", cut, config.NoComplete)
    config.MakeCommand("paste", paste, config.NoComplete)
end

function copy(bp)
    local text = bp.Cursor:GetSelection()
    if text == "" then
        text = bp.Buf:Line(bp.Cursor.Y)
    end
    shell.RunCommand("wl-copy", text)
end

function cut(bp)
    local text = bp.Cursor:GetSelection()
    if text == "" then
        text = bp.Buf:Line(bp.Cursor.Y)
        bp.Buf:RemoveLine(bp.Cursor.Y)
    else
        bp.Cursor:DeleteSelection()
        bp.Cursor:ResetSelection()
    end
    shell.RunCommand("wl-copy", text)
end

function paste(bp)
    local out = shell.RunCommand("wl-paste", "-n")
    if out ~= "" then
        bp.Buf:Insert(bp.Cursor.Loc, out)
    end
end

-- regionNameDisplay.lua - Part of regionHub
-- This script displays the name of the current region in REAPER and shows its color.
-- Right-click to open a context menu for docking options.

local last_region_id = -1
local gfx_w, gfx_h, bar_width = 300, 50, 20
local text_margin = 10

gfx.init("Current Region Display", gfx_w, gfx_h)
gfx.setfont(1, "Calibri", 20)

-- Dock the window by default (1 = docked, 0 = undocked)
gfx.dock(1)

local function getRegionInfo(region_idx)
    if region_idx >= 0 then
        local _, _, _, _, _, _, color = reaper.EnumProjectMarkers3(0, region_idx)
        local name = ({reaper.EnumProjectMarkers3(0, region_idx)})[5]
        local r, g, b = (color >> 16) & 255, (color >> 8) & 255, color & 255
        return name, r / 255, g / 255, b / 255
    end
    return "Not in Region", 0.2, 0.2, 0.2  -- Default values
end

local function drawRegionBar(r, g, b)
    gfx.set(r, g, b)
    gfx.rect(0, 0, bar_width, gfx_h, 1)
end

local function drawRegionName(name)
    gfx.set(1, 1, 1) -- White color for text
    local text_x = bar_width + text_margin
    local _, text_height = gfx.measurestr(name)
    local text_y = (gfx_h - text_height) / 2
    gfx.x, gfx.y = text_x, text_y
    gfx.drawstr(name)
end

local function toggleDocking()
    local dock_state = gfx.dock(-1)
    gfx.dock(dock_state == 0 and 1 or 0)
end

local function handleRightClick()
    local dock_state = gfx.dock(-1)
    local menu_str = dock_state == 0 and "Dock" or "!Dock"
    gfx.x, gfx.y = gfx.mouse_x, gfx.mouse_y  -- Set menu position to mouse cursor
    if gfx.showmenu(menu_str) == 1 then
        toggleDocking()
    end
end

function main()
    local playState = reaper.GetPlayState()
    local pos = (playState == 0) and reaper.GetCursorPosition() or reaper.GetPlayPosition()
    local _, region_idx = reaper.GetLastMarkerAndCurRegion(0, pos)

    if last_region_id ~= region_idx then
        last_region_id = region_idx
        local name, r, g, b = getRegionInfo(region_idx)
        gfx.clear = reaper.ColorToNative(30,30,30)
        drawRegionBar(r, g, b)
        drawRegionName(name)
        gfx.update()
    end

    if gfx.mouse_cap & 2 == 2 then
        handleRightClick()
        gfx.mouse_cap = 0 -- Reset mouse capture state
    end

    reaper.defer(main)
end

main()

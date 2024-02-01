-- Initialize variables
local last_region_id = -1

-- Function to update GUI with current region name
function updateGUI()
    local pos = reaper.GetPlayState() == 0 and reaper.GetCursorPosition() or reaper.GetPlayPosition()
    local _, region_idx = reaper.GetLastMarkerAndCurRegion(0, pos)
    
    if last_region_id ~= region_idx then
        last_region_id = region_idx
        gfx.clear = reaper.ColorToNative(30,30,30) -- Clear window
        gfx.update()

        if region_idx >= 0 then
            local ret, _, _, _, name = reaper.EnumProjectMarkers3(0, region_idx)
            if ret then
                gfx.x = 10
                gfx.y = 10
                gfx.setfont(1, "Calibri", 20)
                gfx.drawstr(name) -- Display region name
            end
        end
    end
end

-- Set up GUI window
gfx.init("Current Region Display", 300, 50)
gfx.clear = reaper.ColorToNative(30,30,30)

-- Main loop
function main()
    updateGUI()
    reaper.defer(main)
end

main()

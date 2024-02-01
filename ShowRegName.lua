-- regionNameDisplay.lua - Part of regionHub
-- This script displays the name of the current region in REAPER.

-- Initialize the variable to keep track of the last region ID encountered
local last_region_id = -1

-- Set up the GUI window for displaying the region name
-- Initializes a graphics window with a title, width, and height
gfx.init("Current Region Display", 300, 50)
gfx.clear = reaper.ColorToNative(30,30,30) -- Set the background color of the window
gfx.setfont(1, "Calibri", 20) -- Set the font type and size for the text

-- Main execution loop of the script
function main()
    -- Determine the current position:
    -- If playback is stopped (GetPlayState() == 0), use the edit cursor position (GetCursorPosition)
    -- Otherwise, use the current play position (GetPlayPosition)
    local pos = reaper.GetPlayState() == 0 and reaper.GetCursorPosition() or reaper.GetPlayPosition()

    -- Fetch the index of the region at the current position
    -- GetLastMarkerAndCurRegion returns several values, but only the region index is needed here
    local _, region_idx = reaper.GetLastMarkerAndCurRegion(0, pos)

    -- Determine the name of the region
    -- If the region index is valid (>= 0), get the name of the region
    -- Otherwise, set the name to "Not in Region"
    local name = region_idx >= 0 and ({reaper.EnumProjectMarkers3(0, region_idx)})[5] or "Not in Region"

    -- Update the display only if the region has changed
    if last_region_id ~= region_idx then
        last_region_id = region_idx -- Update the last region ID
        gfx.clear = reaper.ColorToNative(30,30,30) -- Clear the window for new text
        gfx.x, gfx.y = 10, 10 -- Set the position for the text
        gfx.drawstr(name) -- Draw the region name or "Not in Region"
        gfx.update() -- Refresh the window to show the updated text
    end

    -- Defer the main function to run repeatedly
    -- This creates a loop that allows the script to continually update the display
    reaper.defer(main)
end

-- Start the script by calling the main function
main()

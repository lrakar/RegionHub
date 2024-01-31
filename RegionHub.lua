local isEditingRegion = false
local editedRegionIndex = -1
local editedRegionName = ""
local lastClickTime = 0
local doubleClickThreshold = 0.2 -- Threshold in seconds for double click

local cursorBlinkState = true
local lastBlinkTime = 0
local cursorBlinkRate = 0.2 -- Cursor blink rate in seconds
local cursorPosition = 0 -- Position of the cursor in the edited text

-- Initialize additional global variables
local lastCursorPos = -1
local lastRegionIndex = -1

-- Global variables for display states
local displayStates = {
    showRegion = true,
    showTime = true,
    showFrame = true,
    showBars = true,
    showBeats = true
}

-- Initialize the gfx window
function InitGFX()
    gfx.init("Region Time Display", 300, 120, 0)
    gfx.setfont(1, "Arial", 16)
end

-- Function to determine if a color is light or dark
function IsColorLight(r, g, b)
    local luminance = 0.299 * r + 0.587 * g + 0.114 * b
    return luminance > 0.5
end

-- Function to get region information from the cursor position
function GetRegionFromCursor()
    local cursor_pos = reaper.GetPlayPosition()
    local _, num_markers, num_regions = reaper.CountProjectMarkers()
    for i = 0, num_markers + num_regions - 1 do
        local retval, isrgn, pos, rgnend, name, index, color = reaper.EnumProjectMarkers3(0, i)
        if isrgn and cursor_pos >= pos and cursor_pos < rgnend then
            if color == nil or color == 0 then color = 0x808080 end

            -- Using reaper.ColorFromNative to get the correct RGB values
            local r, g, b = reaper.ColorFromNative(color)
            return name, pos, rgnend, r, g, b, index
        end
    end
    return "Not in a region", -1, -1, 128, 128, 128, -1
end


-- Display the information in the gfx window
-- Display the information in the gfx window
function DisplayInfo(region_name, region_start, r, g, b, cursor_pos, region_index)
    -- Set the entire background to black
    gfx.clear = reaper.ColorToNative(0, 0, 0)

    -- Draw a colored outline on the left side of the window
    local outlineWidth = 30 -- Width of the colored outline
    gfx.set(r/255, g/255, b/255, 1) -- Set the outline color
    gfx.rect(0, 0, outlineWidth, gfx.h, 1) -- Draw the rectangle outline

    -- Set the text color. Use white for better contrast against the black background
    gfx.set(1, 1, 1)

    local info_string = ""
    if region_start ~= -1 then
        local time_in_region, current_frame, measures, full_beats = TimeInfo(region_start, cursor_pos)

        -- Check if we are editing the region name for the current region
        if isEditingRegion and editedRegionIndex == region_index then
            -- Draw the text input field for the region name
            RenderTextInputField()
        else
            -- Regular display of region info
            if displayStates.showRegion then
                info_string = info_string .. "Region: " .. region_name .. "\n"
            end
            if displayStates.showTime then
                info_string = info_string .. string.format("Time: %.3f sec\n", time_in_region)
            end
            if displayStates.showFrame then
                info_string = info_string .. "Frame: " .. current_frame .. "\n"
            end
            if displayStates.showBars then
                info_string = info_string .. "Bars: " .. measures .. "\n"
            end
            if displayStates.showBeats then
                info_string = info_string .. "Beats: " .. full_beats
            end
        end
    else
        if displayStates.showRegion then
            info_string = "Region: " .. region_name
        end
    end

    -- Adjust the text position to start after the colored outline
    gfx.x, gfx.y = outlineWidth + 10, 10
    gfx.drawstr(info_string)
    gfx.update()
end


-- Function to calculate time information
function TimeInfo(region_start, cursor_pos)
    local time_in_region = cursor_pos - region_start
    local frame_rate = reaper.TimeMap_curFrameRate(0)
    local current_frame = math.floor(time_in_region * frame_rate + 0.5)
    local _, measures, _, full_beats, _ = reaper.TimeMap2_timeToBeats(0, time_in_region)
    measures = math.floor(measures + 1)
    full_beats = math.floor(full_beats + 1)
    return time_in_region, current_frame, measures, full_beats
end



-- Function to handle right-click context menu for docking
function HandleDocking()
    if gfx.mouse_cap & 2 == 2 then -- Right-click
        local dock_state = gfx.dock(-1)
        local menu_str = "Dock window|Undock window||" ..
                         (displayStates.showRegion and "!" or "") .. "Show Region|" ..
                         (displayStates.showTime and "!" or "") .. "Show Time|" ..
                         (displayStates.showFrame and "!" or "") .. "Show Frame|" ..
                         (displayStates.showBars and "!" or "") .. "Show Bars|" ..
                         (displayStates.showBeats and "!" or "") .. "Show Beats"

        local menu_sel = gfx.showmenu(menu_str)

        -- Docking Options
        if menu_sel == 1 then
            gfx.dock(dock_state | 1)
        elseif menu_sel == 2 then
            gfx.dock(dock_state & ~1)
        end

        -- Display State Options
        if menu_sel == 3 then  -- Adjusted index for "Show Region"
            displayStates.showRegion = not displayStates.showRegion
        elseif menu_sel == 4 then  -- Adjusted index for "Show Time"
            displayStates.showTime = not displayStates.showTime
        elseif menu_sel == 5 then  -- Adjusted index for "Show Frame"
            displayStates.showFrame = not displayStates.showFrame
        elseif menu_sel == 6 then  -- Adjusted index for "Show Bars"
            displayStates.showBars = not displayStates.showBars
        elseif menu_sel == 7 then  -- Adjusted index for "Show Beats"
            displayStates.showBeats = not displayStates.showBeats
        end
    end
end

function HandleTextInput(char)
    if isEditingRegion then
        if char == 13 then -- Enter key
            -- Ensures the updated region name is sent to Reaper
            UpdateRegionNameInReaper(editedRegionIndex, editedRegionName)
            isEditingRegion = false
            editedRegionIndex = -1
            editedRegionName = ""
            cursorPosition = 0
        elseif char == 8 then -- Backspace key
            if cursorPosition > 0 then
                editedRegionName = editedRegionName:sub(1, cursorPosition - 1) .. editedRegionName:sub(cursorPosition + 1)
                cursorPosition = math.max(0, cursorPosition - 1)
            end
        elseif char == -1 then -- Left arrow key
            cursorPosition = math.max(0, cursorPosition - 1)
        elseif char == -2 then -- Right arrow key
            cursorPosition = math.min(#editedRegionName, cursorPosition + 1)
        elseif char >= 32 and char <= 126 then
            -- Add character to the string (only printable ASCII characters)
            editedRegionName = editedRegionName:sub(1, cursorPosition) .. string.char(char) .. editedRegionName:sub(cursorPosition + 1)
            cursorPosition = cursorPosition + 1
        end
    end
end






function UpdateRegionNameInReaper(regionIndex, newName)
    -- Check if the region index is valid
    if regionIndex == nil or regionIndex < 0 then
        return -- Invalid index, exit the function
    end

    -- Iterate through all markers and regions until we find the matching index
    local _, num_markers, num_regions = reaper.CountProjectMarkers()
    for i = 0, num_markers + num_regions - 1 do
        local retval, isRegion, pos, rgnend, name, markrgnindexnumber, color = reaper.EnumProjectMarkers3(0, i)
        if isRegion and markrgnindexnumber == regionIndex then
            -- We found the region, now update its name
            reaper.SetProjectMarker3(0, markrgnindexnumber, isRegion, pos, rgnend, newName, color)
            break -- Exit the loop after updating the region name
        end
    end
end

function HandleDoubleClick()
    local mx, my = gfx.mouse_x, gfx.mouse_y
    -- Check if the mouse click is within the region name area
    if my >= 10 and my <= 30 then -- Adjust these coordinates as needed
        local currentTime = os.clock()
        if currentTime - lastClickTime < doubleClickThreshold then
            -- Double click detected, start editing the region name
            isEditingRegion = true
            local _, _, _, _, _, _, regionIndex = GetRegionFromCursor()
            editedRegionIndex = regionIndex
            editedRegionName, _, _, _, _, _, _ = GetRegionFromCursor()
            cursorBlinkState = true -- Ensure cursor is visible
            cursorPosition = #editedRegionName -- Position cursor at the end
        else
            -- Single click, position the cursor
            if isEditingRegion and editedRegionIndex == regionIndex then
                PositionCursorAtClick(mx)
                cursorBlinkState = true -- Reset blink state
            end
        end
        lastClickTime = currentTime
    end
end

function PositionCursorAtClick(mx)
    local x = 10 + 4 -- X-coordinate of the text input field plus padding
    for i = 1, #editedRegionName do
        local textWidth, _ = gfx.measurestr(editedRegionName:sub(1, i))
        if mx < x + textWidth then
            cursorPosition = i - 1
            return
        end
    end
    cursorPosition = #editedRegionName
end


function RenderTextInputField()
    if isEditingRegion then
        local x, y = 10, 30
        local width, height = 200, 20

        gfx.set(0.8, 0.8, 0.8, 1)
        gfx.rect(x, y, width, height, true)

        gfx.set(0, 0, 0, 1)
        gfx.x, gfx.y = x + 4, y + 2
        gfx.drawstr(editedRegionName)

        -- Calculate cursor position based on the text length
        local textWidth, textHeight = gfx.measurestr(editedRegionName:sub(1, cursorPosition))
        local cursorX = x + 4 + textWidth

        -- Render the cursor if it's in the blinking 'on' state
        if cursorBlinkState then
            gfx.set(0, 0, 0, 1) -- Cursor color
            gfx.line(cursorX, y + 2, cursorX, y + 2 + textHeight)
        end

        gfx.set(0, 0, 0, 1)
        gfx.rect(x, y, width, height, false)
    end
end


-- Main loop function
function main()
    HandleDocking() -- Check for docking actions

    -- Call the function to handle double clicks
    if gfx.mouse_cap & 1 == 1 then
        HandleDoubleClick()
    end

    -- Get current cursor position and region information
    local cursor_pos = reaper.GetPlayPosition()
    local region_name, region_start, region_end, r, g, b, region_index = GetRegionFromCursor()

    -- Check if the cursor position or region selection has changed
    if cursor_pos ~= lastCursorPos or region_index ~= lastRegionIndex then
        DisplayInfo(region_name, region_start, r, g, b, cursor_pos, region_index)
        lastCursorPos = cursor_pos
        lastRegionIndex = region_index
    end

    local char = gfx.getchar()
    if char ~= -1 then
        HandleTextInput(char)
    end

    -- Update the cursor blink state
    if os.clock() - lastBlinkTime > cursorBlinkRate then
        cursorBlinkState = not cursorBlinkState
        lastBlinkTime = os.clock()
    end

    if char >= 0 then
        reaper.defer(main)
    end
end

InitGFX()
main()



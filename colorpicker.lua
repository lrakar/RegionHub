-- Initialize the main window
local window_title = "Advanced Color Picker"
local window_width = 300
local window_height = 240  -- Adjusted height to remove unnecessary bottom margin
gfx.init(window_title, window_width, window_height)
gfx.setfont(1, "Calibri", 15)

-- Color picker and saturation slider values
local base_color = {r = 0.5, g = 0.5, b = 0.5} -- Base color without saturation adjustments
local saturation = 0.5  -- Initial saturation value
local dragging_color, dragging_saturation = false, false

-- Helper function to draw a color gradient
local function drawColorGradient()
    local gradient_width = window_width - 20
    for x = 10, gradient_width + 10 do
        for y = 70, 170 do
            local r = (x - 10) / gradient_width
            local g = (y - 70) / 100
            gfx.set(r, g, 1 - g)
            gfx.rect(x, y, 1, 1)  -- Draw pixel as a 1x1 rectangle
        end
    end
end

-- Function to draw the saturation slider with gradient background
local function drawSaturationSlider()
    local slider_width = window_width - 20
    for x = 10, slider_width + 10 do
        local blend = (x - 10) / slider_width
        local r, g, b

        if blend <= 0.5 then
            -- Blend from black to base color
            r = blend * 2 * base_color.r
            g = blend * 2 * base_color.g
            b = blend * 2 * base_color.b
        else
            -- Blend from base color to white
            r = base_color.r + (1 - base_color.r) * (blend - 0.5) * 2
            g = base_color.g + (1 - base_color.g) * (blend - 0.5) * 2
            b = base_color.b + (1 - base_color.b) * (blend - 0.5) * 2
        end
        gfx.set(r, g, b)
        gfx.rect(x, 180, 1, 20) -- Draw the gradient slider background
    end
    -- Draw the slider handle
    gfx.set(1, 1, 1)
    gfx.rect(10 + saturation * slider_width, 180, 10, 20)
end

-- Function to adjust color based on saturation slider
local function adjustColorBySaturation(color)
    local function lerp(a, b, t)
        return a + (b - a) * t
    end

    local adjusted_color = {r = color.r, g = color.g, b = color.b}

    -- Adjust color saturation (0 is black, 0.5 is the color, 1 is white)
    if saturation <= 0.5 then
        -- Blend towards black
        local blend = saturation * 2
        adjusted_color.r = lerp(0, color.r, blend)
        adjusted_color.g = lerp(0, color.g, blend)
        adjusted_color.b = lerp(0, color.b, blend)
    else
        -- Blend towards white
        local blend = (saturation - 0.5) * 2
        adjusted_color.r = lerp(color.r, 1, blend)
        adjusted_color.g = lerp(color.g, 1, blend)
        adjusted_color.b = lerp(color.b, 1, blend)
    end

    return adjusted_color
end

-- Main loop
function main()
    -- Draw background
    gfx.set(0.1, 0.1, 0.1) -- Dark background color
    gfx.rect(0, 0, window_width, window_height)

    -- Draw color gradient
    drawColorGradient()

    -- Handle mouse input for color picking and saturation adjustment
    if gfx.mouse_cap & 1 == 1 then
        if not dragging_color and not dragging_saturation then
            if gfx.mouse_x > 10 and gfx.mouse_x < window_width - 10 and gfx.mouse_y > 70 and gfx.mouse_y < 170 then
                dragging_color = true
            elseif gfx.mouse_x > 10 and gfx.mouse_x < window_width - 10 and gfx.mouse_y > 180 and gfx.mouse_y < 200 then
                dragging_saturation = true
            end
        end
    else
        dragging_color, dragging_saturation = false, false
    end

    if dragging_color then
        base_color.r = (gfx.mouse_x - 10) / (window_width - 20)
        base_color.g = (gfx.mouse_y - 70) / 100
        base_color.b = 1 - base_color.g
    end

    if dragging_saturation then
        saturation = (gfx.mouse_x - 10) / (window_width - 20)
        saturation = math.max(0, math.min(saturation, 1))
    end

    -- Adjust and draw color preview with saturation
    local display_color = adjustColorBySaturation(base_color)
    gfx.set(display_color.r, display_color.g, display_color.b)
    gfx.rect(10, 10, window_width - 20, 50)  -- Adjusted width for consistency

    -- Draw saturation slider with gradient background
    drawSaturationSlider()

    -- Update UI
    gfx.update()
    if gfx.getchar() >= 0 then
        reaper.defer(main)
    end
end

main()

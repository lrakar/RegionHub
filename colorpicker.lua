-- Initialize the main window
local window_title = "Advanced Color Picker with Lightness Slider"
local window_width = 300
local window_height = 260
gfx.init(window_title, window_width, window_height)
gfx.setfont(1, "Calibri", 15)

-- Color picker and lightness slider values
local color = {r = 0.5, g = 0.5, b = 0.5, lightness = 0.5}
local dragging_color, dragging_lightness = false, false

-- Helper function to draw a color gradient
local function drawColorGradient()
    for x = 10, window_width - 20 do
        for y = 70, 170 do
            local r = (x - 10) / (window_width - 30)
            local g = (y - 70) / 100
            gfx.set(r, g, 1 - g)
            gfx.rect(x, y, 1, 1)  -- Draw pixel as a 1x1 rectangle
        end
    end
end

-- Function to adjust color based on lightness slider
local function adjustColorByLightness()
    -- Adjust color lightness (0 is black, 0.5 is the color, 1 is white)
    if color.lightness <= 0.5 then
        -- Blend towards black
        local blend = color.lightness * 2
        color.r = color.r * blend
        color.g = color.g * blend
        color.b = color.b * blend
    else
        -- Blend towards white
        local blend = (color.lightness - 0.5) * 2
        color.r = color.r + (1 - color.r) * blend
        color.g = color.g + (1 - color.g) * blend
        color.b = color.b + (1 - color.b) * blend
    end
end

-- Main loop
function main()
    -- Draw background
    gfx.set(0.1, 0.1, 0.1) -- Dark background color
    gfx.rect(0, 0, window_width, window_height)

    -- Draw color gradient
    drawColorGradient()

    -- Handle mouse input for color picking
    if gfx.mouse_cap & 1 == 1 then
        if not dragging_color and not dragging_lightness then
            if gfx.mouse_x > 10 and gfx.mouse_x < window_width - 10 and gfx.mouse_y > 70 and gfx.mouse_y < 170 then
                dragging_color = true
            elseif gfx.mouse_x > 10 and gfx.mouse_x < window_width - 10 and gfx.mouse_y > 180 and gfx.mouse_y < 200 then
                dragging_lightness = true
            end
        end
    else
        dragging_color, dragging_lightness = false, false
    end

    if dragging_color then
        color.r = (gfx.mouse_x - 10) / (window_width - 30)
        color.g = (gfx.mouse_y - 70) / 100
        color.b = 1 - color.g
    end

    if dragging_lightness then
        color.lightness = (gfx.mouse_x - 10) / (window_width - 30)
        color.lightness = math.max(0, math.min(color.lightness, 1))
        adjustColorByLightness()
    end

    -- Draw color preview with adjusted lightness
    adjustColorByLightness()  -- Update color with lightness
    gfx.set(color.r, color.g, color.b)
    gfx.rect(10, 10, window_width - 20, 50)

    -- Draw lightness slider
    gfx.set(0.3, 0.3, 0.3)
    gfx.rect(10, 180, window_width - 20, 20)
    gfx.set(1, 1, 1)
    gfx.rect(10 + color.lightness * (window_width - 30), 180, 10, 20)

    -- Update UI
    gfx.update()
    if gfx.getchar() >= 0 then
        reaper.defer(main)
    end
end

main()

local gears = require("gears")

local popup_stack = {}
local grabber_running = false

local function any_button_pressed(mouse)
    for _, b in ipairs(mouse.buttons or {}) do
        if b then return true end
    end
    return false
end

local function safe_geometry(widget)
    local ok, geo = pcall(function() return widget and widget:geometry() end)
    if not ok or not geo then return nil end
    return geo
end

local function is_widget_on_screen(widget)
    local geo = safe_geometry(widget)
    if not geo then return false end
    if geo.x == nil or geo.y == nil or geo.width == nil or geo.height == nil then
        return false
    end
    return not (geo.x + geo.width <= 0 or geo.y + geo.height <= 0 or geo.x >= 65536 or geo.y >= 65536)
end

local function get_mouse_coords(mouse_param)
    -- Если передан параметр mouse с coords
    if mouse_param and type(mouse_param) == "table" and mouse_param.coords then
        return mouse_param:coords()
    end
    
    -- Используем глобальную переменную mouse
    if mouse and mouse.coords then
        return mouse.coords()
    end
    
    -- Запасной вариант
    if type(mouse_param) == "table" and mouse_param.x and mouse_param.y then
        return { x = mouse_param.x, y = mouse_param.y }
    end
    
    return nil
end

local function point_in_geo(px, py, geo)
    return px >= geo.x and px <= geo.x + geo.width and py >= geo.y and py <= geo.y + geo.height
end

local function click_inside_widget(widget, mouse)
    if not is_widget_on_screen(widget) then return false end
    local geo = safe_geometry(widget)
    if not geo then return false end
    local coords = get_mouse_coords(mouse)
    if not coords then return false end
    return point_in_geo(coords.x, coords.y, geo)
end

local function cleanup_hidden()
    for i = #popup_stack, 1, -1 do
        local p = popup_stack[i]
        if not p.is_shown_func() then
            table.remove(popup_stack, i)
        end
    end
end

local function handle_mouse_outside(mouse)
    cleanup_hidden()
    if #popup_stack == 0 then
        grabber_running = false
        return false
    end

    local top = popup_stack[#popup_stack]
    if not top or not top.is_shown_func or not top.is_shown_func() then
        return true
    end

    local inside = click_inside_widget(top.widget, mouse)
    local coords = get_mouse_coords(mouse)
    local geo = safe_geometry(top.widget)
    
    -- Отладка
    if coords and geo then
        print(string.format("[DEBUG] Mouse: %d,%d | Widget: %d,%d %dx%d | Inside: %s", 
            coords.x, coords.y, geo.x, geo.y, geo.width, geo.height, tostring(inside)))
    end
    
    if inside then
        grabber_running = false
        return false -- возвращаемся в popup
    end

    if any_button_pressed(mouse) then
        -- клик вне popup'а
        if top.callback then
            pcall(top.callback)
        end
        table.remove(popup_stack, #popup_stack)
        
        -- Проверяем, есть ли предыдущий popup
        if #popup_stack > 0 then
            local prev = popup_stack[#popup_stack]
            if prev and prev.is_shown_func and prev.is_shown_func() then
                -- Проверяем, находится ли мышь вне предыдущего popup
                local coords = get_mouse_coords(mouse)
                if coords and not click_inside_widget(prev.widget, mouse) then
                    -- Мышь вне предыдущего popup - продолжаем grabber
                    return true
                end
            end
        end
        
        grabber_running = false
        return false
    end

    return true
end

local function start_grabber_if_outside(widget, is_shown_func)
    if not grabber_running and is_shown_func() then
        local coords = get_mouse_coords()
        if coords and not click_inside_widget(widget, { coords = function() return coords end }) then
            grabber_running = true
            mousegrabber.run(handle_mouse_outside, "left_ptr")
        end
    end
end

local function add_popup_to_stack(widget, callback, is_shown_func)
    assert(widget, "widget required")
    assert(is_shown_func, "is_shown_func required")
    
    table.insert(popup_stack, {
        widget = widget,
        callback = callback,
        is_shown_func = is_shown_func
    })
    
    -- Запускаем grabber сразу, если мышь вне popup
    gears.timer.delayed_call(function()
        start_grabber_if_outside(widget, is_shown_func)
    end)
    
    -- Настраиваем mouse::leave для повторного запуска
    widget:connect_signal('mouse::leave', function()
        start_grabber_if_outside(widget, is_shown_func)
    end)
end

local function remove_popup_from_stack(widget)
    for i = #popup_stack, 1, -1 do
        if popup_stack[i].widget == widget then
            table.remove(popup_stack, i)
            break
        end
    end
end

-- API: возвращает start/stop функции
local function add_click_outside_positioned(widget, callback, is_shown_func)
    local function start_cb()
        if is_shown_func and is_shown_func() then
            add_popup_to_stack(widget, callback, is_shown_func)
        end
    end

    local function stop_cb()
        remove_popup_from_stack(widget)
    end

    return start_cb, stop_cb
end

return add_click_outside_positioned
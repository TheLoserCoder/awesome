-- ~/.config/awesome/custom/utils/window_focus.lua
local awful = require("awful")

local WindowFocus = {}

-- Переключение на окно по имени приложения
function WindowFocus.focus_by_name(app_name)
    for _, c in ipairs(client.get()) do
        if c.name and c.name:lower():find(app_name:lower()) then
            if c.first_tag then
                c.first_tag:view_only()
            end
            client.focus = c
            c:raise()
            return true
        end
    end
    return false
end

-- Переключение на окно по классу
function WindowFocus.focus_by_class(app_class)
    for _, c in ipairs(client.get()) do
        if c.class and c.class:lower():find(app_class:lower()) then
            if c.first_tag then
                c.first_tag:view_only()
            end
            client.focus = c
            c:raise()
            return true
        end
    end
    return false
end

-- Переключение на окно по PID плеера
function WindowFocus.focus_by_player_pid(player_bus, callback)
    awful.spawn.easy_async(
        { "playerctl", "--player=" .. player_bus, "metadata", "mpris:pid" },
        function(stdout)
            local pid = tonumber(stdout:match("%d+"))
            if not pid then 
                if callback then callback(false) end
                return 
            end
            
            for _, c in ipairs(client.get()) do
                if c.pid == pid then
                    c:jump_to()
                    if callback then callback(true) end
                    return
                end
            end
            
            if callback then callback(false) end
        end
    )
end

return WindowFocus
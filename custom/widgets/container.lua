-- ~/.config/awesome/custom/widgets/container.lua
local wibox = require("wibox")

local Container = {}
Container.__index = Container

-- Создание контейнера с фиксированным размером
function Container.new(config)
    config = config or {}
    local self = setmetatable({}, Container)
    
    -- Настройки
    self.width = config.width
    self.height = config.height
    self.content = config.content
    
    -- Создаем контейнер
    self:_create_widget()
    
    return self
end

-- Создание виджета
function Container:_create_widget()
    self.widget = wibox.widget {
        {
            self.content,
            halign = "center",
            valign = "center",
            widget = wibox.container.place
        },
        forced_width = self.width,
        forced_height = self.height,
        widget = wibox.container.background
    }
end

-- Установка содержимого
function Container:set_content(content)
    self.content = content
    self.widget:get_children_by_id("place")[1]:set_widget(content)
end

return Container
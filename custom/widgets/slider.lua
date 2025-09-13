-- ~/.config/awesome/custom/widgets/slider.lua
local gears = require("gears")
local wibox = require("wibox")
local awful = require("awful")

local Slider = {}
Slider.__index = Slider

-- Получаем зависимости
local rubato = require("custom.utils.rubato")

-- Создание нового slider на основе wibox.widget.slider
function Slider.new(config)
    config = config or {}
    local self = setmetatable({}, Slider)
    
    -- Создаем базовый slider
    self.widget = wibox.widget {
        bar_shape = gears.shape.rounded_bar,
        bar_height = config.height or 6,
        bar_color = config.bg_color or "#2A2A3C",
        bar_active_color = config.bar_active_color or config.fg_color or "#FFF77A",
        handle_shape = gears.shape.circle,
        handle_color = config.handle_color or "#7AA2F7",
        handle_width = 0, -- Изначально скрыта
        handle_border_width = 0,
        minimum = config.minimum or 0,
        maximum = config.maximum or 100,
        value = 25,
        forced_width = config.width or 120,
        forced_height = config.height or 6,
        widget = wibox.widget.slider
    }
    
    -- Настраиваем анимации
    self:_setup_animations(config)
    
    return self
end

-- Установка значения
function Slider:set_value(value)
    self.widget.value = value
end

-- Получение значения
function Slider:get_value()
    return self.widget.value
end

-- Установка минимума
function Slider:set_minimum(min)
    self.widget.minimum = min
end

-- Установка максимума
function Slider:set_maximum(max)
    self.widget.maximum = max
end

-- Подключение сигналов
function Slider:connect_signal(signal, callback)
    self.widget:connect_signal(signal, callback)
end

-- Отключение сигналов
function Slider:disconnect_signal(signal, callback)
    self.widget:disconnect_signal(signal, callback)
end

-- Установка кнопок
function Slider:buttons(buttons)
    self.widget:buttons(buttons)
end

-- Настройка анимаций
function Slider:_setup_animations(config)
    local handle_size = config.handle_width or 12
    
    -- Анимация handle через rubato
    self.handle_anim = rubato.timed {
        duration = 0.3,
        intro = 0.1,
        subscribed = function(value)
            self.widget.handle_width = value
        end
    }
    
    -- Обработчики событий мыши
    self.widget:connect_signal("mouse::enter", function()
        self.handle_anim.target = handle_size
    end)
    
    self.widget:connect_signal("mouse::leave", function()
        self.handle_anim.target = 0
    end)
end

return Slider
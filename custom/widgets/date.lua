-- ~/.config/awesome/custom/widgets/date.lua
local gears = require("gears")
local wibox = require("wibox")
local awful = require("awful")
local beautiful = require("beautiful")

local Date = {}
Date.__index = Date

-- Получаем зависимости
local Button2 = require("custom.widgets.button_2")
local Clock = require("custom.widgets.clock")

-- Создание виджета даты
function Date.new(config)
    config = config or {}
    local self = setmetatable({}, Date)
    
    -- Создаем компоненты
    self.clock = Clock.new(config.clock or {})
    
    -- Создаем виджеты
    self:_create_widgets()
    
    return self
end

-- Создание виджетов
function Date:_create_widgets()
    -- Получаем цвета из beautiful
    
    -- Создаем календарь с встроенными часами
    self.calendar = awful.widget.calendar_popup.month({
        start_sunday = false,
        long_weekdays = false,
        margin = 8,
        style_month = {
            border_width = 0,
            bg_color = beautiful.background,
            padding = 8,
            shape = function(cr, width, height)
                gears.shape.rounded_rect(cr, width, height, 8)
            end
        },
        style_header = {
            bg_color = "transparent",
            fg_color = beautiful.text,
            border_width = 0,
            markup = function(t) return '<b>' .. t .. '</b>' end
        },
        style_weekday = {
            fg_color = beautiful.text_secondary,
            bg_color = "transparent",
            border_width = 0,
            markup = function(t) return '<b>' .. t .. '</b>' end
        },
        style_normal = {
            fg_color = beautiful.text,
            bg_color = "transparent",
            border_width = 0,
            shape = gears.shape.circle,
            markup = function(t) return t end
        },
        style_focus = {
            fg_color = beautiful.background,
            bg_color = beautiful.accent,
            border_width = 0,
            shape = gears.shape.circle,
            markup = function(t) return '<b>' .. t .. '</b>' end
        }
    })
    
    -- Оборачиваем часы в кнопку
    self.button = Button2.new({
        content = self.clock.widget,
        width = 80,
        height = 24,
        on_click = function()
            -- Клик обрабатывается календарем
        end
    })
    
    -- Привязываем календарь к виджету часов
    self.calendar:attach(self.button.widget, "tc", { on_pressed = true, on_hover = false })
    
    -- Основной виджет - это кнопка с часами
    self.widget = self.button.widget
end

return Date
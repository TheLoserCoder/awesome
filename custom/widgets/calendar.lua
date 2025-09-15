-- ~/.config/awesome/custom/widgets/calendar.lua
local wibox = require("wibox")
local awful = require("awful")

local Calendar = {}
Calendar.__index = Calendar

-- Получаем зависимости
local Provider = require("custom.widgets.provider")

-- Создание виджета календаря
function Calendar.new(config)
    config = config or {}
    local self = setmetatable({}, Calendar)
    
    -- Создаем виджет
    self:_create_widget()
    
    return self
end

-- Создание виджета
function Calendar:_create_widget()
    -- Получаем цвета
    local colors = Provider.get_colors()
    
    -- Создаем календарь
    self.calendar = awful.widget.calendar_popup.month({
        start_sunday = false,
        long_weekdays = false,
        margin = 8,
        style_month = {
            border_width = 0,
            bg_color = colors.background,
            padding = 8,
            shape = function(cr, width, height)
                require("gears").shape.rounded_rect(cr, width, height, 8)
            end
        },
        style_header = {
            bg_color = colors.primary,
            fg_color = colors.text_secondary,
            markup = function(t) return '<b>' .. t .. '</b>' end
        },
        style_weekday = {
            fg_color = colors.text_secondary,
            markup = function(t) return '<b>' .. t .. '</b>' end
        },
        style_normal = {
            fg_color = colors.text,
            bg_color = "transparent",
            border_width = 0,
            shape = require("gears").shape.circle,
            markup = function(t) return t end
        },
        style_focus = {
            fg_color = colors.background,
            bg_color = colors.accent,
            border_width = 0,
            shape = require("gears").shape.circle,
            markup = function(t) return '<b>' .. t .. '</b>' end
        }
    })
    
    self.widget = self.calendar
end

-- Показать календарь
function Calendar:show()
    self.calendar:toggle()
end

-- Скрыть календарь
function Calendar:hide()
    self.calendar:hide()
end

return Calendar
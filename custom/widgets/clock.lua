-- ~/.config/awesome/custom/widgets/clock.lua
local wibox = require("wibox")

local Clock = {}
Clock.__index = Clock

-- Получаем зависимости
local settings = require("custom.settings")

-- Создание виджета часов
function Clock.new(config)
    config = config or {}
    local self = setmetatable({}, Clock)
    
    -- Настройки из settings или config
    local clock_settings = settings.widgets.clock
    self.show_seconds = config.show_seconds or clock_settings.show_seconds
    self.show_date = config.show_date or clock_settings.show_date
    self.show_time = config.show_time or clock_settings.show_time
    self.date_format = config.date_format or clock_settings.date_format
    self.time_format = config.time_format or (self.show_seconds and "%H:%M:%S" or clock_settings.time_format)
    self.separator = config.separator or clock_settings.separator
    
    -- Создаем виджет
    self:_create_widget()
    
    return self
end

-- Создание виджета
function Clock:_create_widget()
    -- Формируем формат отображения
    local format_parts = {}
    
    if self.show_date then
        table.insert(format_parts, self.date_format)
    end
    
    if self.show_time then
        table.insert(format_parts, self.time_format)
    end
    
    local format_string = table.concat(format_parts, self.separator)
    
    -- Создаем textclock виджет
    self.widget = wibox.widget.textclock(format_string)
end

return Clock
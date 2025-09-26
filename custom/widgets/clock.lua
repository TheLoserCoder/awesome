-- ~/.config/awesome/custom/widgets/clock.lua
local wibox = require("wibox")

local Clock = {}
Clock.__index = Clock

-- Получаем зависимости
local ThemeProvider = require("custom.theme.theme_provider")
local ColorHSL = require("custom.utils.color_hsl")
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
    self.widget = wibox.widget.textclock('<span color="' .. settings.colors.text .. '">' .. format_string .. '</span>')
    self.widget.font = settings.fonts.main .. " " .. settings.fonts.widget_size
    
    -- Подписываемся на изменения темы
    local theme_provider = ThemeProvider.get()
    theme_provider:subscribe(function(t, prev_theme, next_theme)
        local from_color = prev_theme.text or settings.colors.text
        local to_color = next_theme.text or settings.colors.text
        
        local h1,s1,l1,a1 = ColorHSL.hex_to_hsl(from_color)
        local h2,s2,l2,a2 = ColorHSL.hex_to_hsl(to_color)
        
        local h,s,l,a = ColorHSL.lerp_hsl(h1,s1,l1,a1, h2,s2,l2,a2, t)
        local color = ColorHSL.hsl_to_hex(h,s,l,a)
        
        -- Обновляем формат с новым цветом
        self.widget.format = '<span color="' .. color .. '">' .. format_string .. '</span>'
    end)
end

return Clock
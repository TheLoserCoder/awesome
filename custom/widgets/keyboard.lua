-- ~/.config/awesome/custom/widgets/keyboard.lua
local gears = require("gears")
local wibox = require("wibox")
local awful = require("awful")
local beautiful = require("beautiful")

local Keyboard = {}
Keyboard.__index = Keyboard

-- Получаем зависимости
local Button2 = require("custom.widgets.button_2")
local ThemeProvider = require("custom.theme.theme_provider")
local settings = require("custom.settings")

-- Создание виджета раскладки
function Keyboard.new(config)
    config = config or {}
    local self = setmetatable({}, Keyboard)
    
    -- Создаем стандартный виджет раскладки
    self.keyboard_layout = awful.widget.keyboardlayout()
    
    -- Создаем виджеты
    self:_create_widgets()
    self:_setup_theme_listener()
    
    return self
end

-- Создание виджетов
function Keyboard:_create_widgets()
    -- Используем стандартный виджет раскладки с цветом из beautiful
    self.keyboard_widget = wibox.widget {
        self.keyboard_layout,
        fg = beautiful.text or "#FFFFFF",
        widget = wibox.container.background
    }
    
    -- Оборачиваем в кнопку
    self.button = Button2.new({
        content = self.keyboard_widget,
        width = 32,
        height = 24,
        on_click = function()
            self.keyboard_layout:next_layout()
        end
    })
    
    self.widget = self.button.widget
end

-- Настройка слушателя темы
function Keyboard:_setup_theme_listener()
    local theme_provider = ThemeProvider.get()
    
    theme_provider:subscribe(function(t, prev_theme, next_theme)
        if t >= 1 and next_theme.text then -- Обновляем только в конце анимации
            self.keyboard_widget.fg = next_theme.text
        end
    end)
end

return Keyboard
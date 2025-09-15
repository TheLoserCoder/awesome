-- ~/.config/awesome/custom/widgets/keyboard.lua
local gears = require("gears")
local wibox = require("wibox")
local awful = require("awful")

local Keyboard = {}
Keyboard.__index = Keyboard

-- Получаем зависимости
local Button = require("custom.widgets.button")

-- Создание виджета раскладки
function Keyboard.new(config)
    config = config or {}
    local self = setmetatable({}, Keyboard)
    
    -- Создаем стандартный виджет раскладки
    self.keyboard_layout = awful.widget.keyboardlayout()
    
    -- Создаем виджеты
    self:_create_widgets()
    
    return self
end

-- Создание виджетов
function Keyboard:_create_widgets()
    -- Оборачиваем стандартный виджет в кнопку
    self.button = Button.new({
        content = self.keyboard_layout,
        width = 32,
        height = 24,
        on_click = function()
            -- Используем встроенную функциональность переключения
            self.keyboard_layout:next_layout()
        end
    })
    
    self.widget = self.button.widget
end

return Keyboard
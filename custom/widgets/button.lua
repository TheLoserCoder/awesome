-- ~/.config/awesome/custom/widgets/button.lua
local gears = require("gears")
local wibox = require("wibox")
local awful = require("awful")

local Button = {}
Button.__index = Button

-- Получаем зависимости
local rubato = require("custom.utils.rubato")
local Provider = require("custom.widgets.provider")
local Container = require("custom.widgets.container")
local ColorAnimator = require("custom.utils.color_animator")

-- Создание новой кнопки
function Button.new(config)
    config = config or {}
    local self = setmetatable({}, Button)
    
    -- Настройки
    self.content = config.content or wibox.widget.textbox("Button")
    self.width = config.width 
    self.height = config.height 
    self.on_click = config.on_click or function() end
    self.selected = false
    self.halign = config.halign or "center"
    self.valign = config.valign or "center"
    self.margins = config.margins or 4
    
    -- Цвета
    local colors = Provider.get_colors()
    self.bg_default = config.bg_default or colors.surface
    self.bg_hover = config.bg_hover or "#3A3A4C80"
    self.bg_selected = config.bg_selected or colors.accent .. "40"
    self.shape = config.shape or gears.shape.rounded_rect
    
    -- Создаем виджеты
    self:_create_widgets()
    self:_setup_animations()
    self:_setup_events()
    
    return self
end

-- Создание внутренних виджетов
function Button:_create_widgets()
    -- Анимируемая кнопка
    self.inner_button = wibox.widget {
        {
            {
                self.content,
                halign = self.halign,
                valign = self.valign,
                widget = wibox.container.place
            },
            margins = self.margins,
            widget = wibox.container.margin
        },
        forced_width = self.width,
        forced_height = self.height,
        bg = self.bg_default,
        shape = self.shape,
        widget = wibox.container.background
    }
    
    -- Оборачиваем в контейнер с фиксированным размером
    self.widget = Container.new({
        width = self.width,
        height = self.height,
        content = self.inner_button
    }).widget
end

-- Настройка анимаций
function Button:_setup_animations()
    -- Анимация hover (плавная смена цвета)
    self.color_animator = ColorAnimator.new({
        duration = 0.3,
        easing = rubato.quadratic,
        from_color = self.bg_default,
        callback = function(color)
            if not self.selected then
                self.inner_button.bg = color
            end
        end
    })
    

end

-- Настройка событий
function Button:_setup_events()
    -- Наведение мыши
    self.widget:connect_signal("mouse::enter", function()
        if not self.selected then
            self.color_animator:animate_to(self.bg_hover)
        end
    end)
    
    -- Покидание мыши
    self.widget:connect_signal("mouse::leave", function()
        if not self.selected then
            self.color_animator:animate_to(self.bg_default)
        end
    end)
    
    -- Нажатие кнопки
    self.widget:buttons(gears.table.join(
        awful.button({}, 1, function()
            -- Вызываем callback без анимации
            self.on_click()
        end)
    ))
end

-- Установка содержимого кнопки
function Button:set_content(content)
    self.content = content
    -- Обновляем содержимое в place контейнере
    self.inner_button:get_children()[1]:get_children()[1]:set_widget(content)
end

-- Установка callback для клика
function Button:set_on_click(callback)
    self.on_click = callback
end

-- Установка цвета фона
function Button:set_bg(color)
    self.bg_default = color
    if not self.selected then
        self.inner_button.bg = color
        self.color_animator:set_color(color)
    end
end

-- Установка состояния selected
function Button:set_selected(selected)
    self.selected = selected
    if selected then
        self.inner_button.bg = self.bg_selected
        self.color_animator:set_color(self.bg_selected)
    else
        self.inner_button.bg = self.bg_default
        self.color_animator:set_color(self.bg_default)
    end
end

return Button
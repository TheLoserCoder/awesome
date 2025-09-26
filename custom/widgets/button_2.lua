-- ~/.config/awesome/custom/widgets/button_2.lua
local gears = require("gears")
local wibox = require("wibox")
local awful = require("awful")
local beautiful = require("beautiful")
local settings = require("custom.settings")

local BaseWidget = require("custom.widgets.base_widgets.base_widget")

local Button2 = {}
Button2.__index = Button2
setmetatable(Button2, {__index = BaseWidget})
local rubato = require("custom.utils.rubato")
local Container = require("custom.widgets.base_widgets.container")
local Text = require("custom.widgets.base_widgets.text")

function Button2.new(config)
    config = config or {}
    local self = setmetatable({}, Button2)
    
    -- Инициализируем BaseWidget
    BaseWidget.new(self, config)

    
    self.content = config.content or Text.new({text = "Button", theme_color = "text"})
    self.width = config.width 
    self.height = config.height 
    self.on_click = config.on_click or function() end
    self.close_control = config.close_control or false
    self.selected = false
    self.halign = config.halign or "center"
    self.valign = config.valign or "center"
    self.margins = config.margins or 4
    
    self.bg_default = config.bg_default or settings.colors.surface
    self.bg_hover = config.bg_hover or settings.colors.accent_alt
    self.bg_selected = config.bg_selected or settings.colors.accent
    self.shape = config.shape or gears.shape.rounded_rect
    
    self:_create_widgets()
    self:_setup_animations()
    self:_setup_events()
    self:_setup_theme_listener()
    

    
    return self
end

function Button2:_create_widgets()
    self.widget = Container.new({
        theme_color = "surface",
        width = self.width,
        height = self.height,
        content = self.content,
        halign = self.halign,
        valign = self.valign,
        margins = self.margins,
        shape = self.shape
    })
end

function Button2:_setup_animations()
    self.hover_anim = rubato.timed {
        duration = 0.3,
        easing = rubato.quadratic,
        pos = 0,
        subscribed = function(pos)
            if not self.selected then
                local ColorHSL = require("custom.utils.color_hsl")
                local h1,s1,l1,a1 = ColorHSL.hex_to_hsl(self.bg_default)
                local h2,s2,l2,a2 = ColorHSL.hex_to_hsl(self.bg_hover)
                local h,s,l,a = ColorHSL.lerp_hsl(h1,s1,l1,a1, h2,s2,l2,a2, pos)
                self.widget:set_bg(ColorHSL.hsl_to_hex(h,s,l,a))
            end
        end
    }
end

function Button2:_setup_events()
    self.widget:connect_signal("mouse::enter", function()
        if not self.selected then
            self.hover_anim.target = 1
        end
    end)
    
    self.widget:connect_signal("mouse::leave", function()
        if not self.selected then
            self.hover_anim.target = 0
        end
    end)
    
    self.widget:connect_signal("button::press", function(_, _, _, button)
        if button == 1 then
            if not self.selected then
                self.hover_anim.target = 0
            end
            if self.close_control then
                local GlobalStorage = require("custom.utils.global_storage")
                GlobalStorage.set("control_center_open", false)
            end
            self.on_click()
        end
    end)
end

function Button2:set_content(content)
    self.content = content
    -- Обновляем содержимое через Container
    if self.widget and self.widget.set_content then
        self.widget:set_content(content)
    end
end

function Button2:set_on_click(callback)
    self.on_click = callback
end

function Button2:set_bg(color)
    self.bg_default = color
    if not self.selected then
        self.widget:set_bg(color)
    end
end

function Button2:set_selected(selected, selected_color)
    self.selected = selected
    if selected then
        local color = selected_color or self.bg_selected
        self.widget:set_bg(color)
    else
        self.widget:set_bg(self.bg_default)
    end
end

function Button2:_setup_theme_listener()
    -- Получаем цвета из beautiful при создании
    self.bg_default = beautiful.surface or self.bg_default
    self.bg_hover = beautiful.surface_alt or self.bg_hover
    self.bg_selected = beautiful.accent or self.bg_selected
    
    -- Устанавливаем обработчик темы через BaseWidget
    self:set_theme_handler(function(_, t, prev_theme, next_theme)
        if t >= 1 then -- Обновляем только в конце анимации
            if next_theme.surface then
                self.bg_default = next_theme.surface
            end
            if next_theme.surface_alt then
                self.bg_hover = next_theme.surface_alt
            end
            if next_theme.accent then
                self.bg_selected = next_theme.accent
            end
            
            -- Обновляем текущий фон если не выбрана
            if not self.selected then
                self.widget:set_bg(self.bg_default)
            end
        end
    end)
end

return Button2
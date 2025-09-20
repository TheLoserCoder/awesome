-- ~/.config/awesome/custom/widgets/control_center.lua
local gears = require("gears")
local wibox = require("wibox")
local awful = require("awful")

local ControlCenter = {}
ControlCenter.__index = ControlCenter

local Button = require("custom.widgets.button")
local Popup = require("custom.widgets.popup")
local Volume = require("custom.widgets.volume")
local Poweroff = require("custom.widgets.poweroff")
local Provider = require("custom.widgets.provider")
local settings = require("custom.settings")

function ControlCenter.new(s)
    local self = setmetatable({}, ControlCenter)
    
    self.screen = s or awful.screen.focused()
    self:_create_widgets()
    
    return self
end

function ControlCenter:_create_widgets()
    local colors = Provider.get_colors()
    
    -- Кнопка с иконкой awesome
    local awesome_icon = wibox.widget {
        text = settings.icons.system.awesome,
        font = settings.fonts.icon .. " 12",
        align = "center",
        valign = "center",
        fg = colors.text,
        widget = wibox.widget.textbox
    }
    
    local control_button = Button.new({
        content = awesome_icon,
        width = 24,
        height = 24,
        on_click = function()
            self:_toggle_popup()
        end
    })
    
    self.widget = control_button.widget
    
    -- Создаем виджет громкости
    self.volume = Volume.new({
        width = 200,
        show_icon = true
    })
    
    -- Создаем виджет poweroff
    self.poweroff = Poweroff.new()
    
    -- Создаем кнопки из настроек
    local button_widgets = {}
    
    for i, button_config in ipairs(settings.widgets.control_center.buttons) do
        local button_widget
        
        if button_config.id == "layout" then
            -- Специальная обработка для layoutbox
            local Layoutbox = require("custom.widgets.layoutbox")
            local layoutbox_widget = Layoutbox.new(self.screen)
            
            button_widget = Button.new({
                content = layoutbox_widget.widget,
                width = 40,
                height = 40,
                shape = gears.shape.circle
            })
        else
            -- Обычные кнопки
            local icon_widget = wibox.widget {
                text = button_config.icon,
                font = settings.fonts.icon .. " 12",
                align = "center",
                valign = "center",
                fg = colors.text,
                widget = wibox.widget.textbox
            }
            
            button_widget = Button.new({
                content = icon_widget,
                width = 40,
                height = 40,
                shape = gears.shape.circle,
                on_click = function()
                    if button_config.command:match("^awesome%..*") then
                        -- Выполняем Lua код
                        local func = load(button_config.command)
                        if func then func() end
                    else
                        -- Запускаем команду
                        awful.spawn(button_config.command)
                    end
                end
            })
        end
        
        table.insert(button_widgets, button_widget.widget)
    end
    
    -- Создаем ряд кнопок с отступами
    local buttons_row_widgets = {}
    
    for i, widget in ipairs(button_widgets) do
        if i == 1 or i == #button_widgets then
            -- Крайние кнопки без отступов
            table.insert(buttons_row_widgets, widget)
        else
            -- Средние кнопки с отступами
            table.insert(buttons_row_widgets, {
                widget,
                left = 8,
                right = 8,
                widget = wibox.container.margin
            })
        end
    end
    
    local buttons_row = wibox.widget {
        layout = wibox.layout.flex.horizontal
    }
    
    for _, widget in ipairs(buttons_row_widgets) do
        buttons_row:add(widget)
    end
    
    -- Контент popup
    local content = wibox.widget {
        {
            self.volume.widget,
          
            widget = wibox.container.margin
        },
        {
            buttons_row,
            
            widget = wibox.container.margin
        },
        {
            self.poweroff.widget,
           
            widget = wibox.container.margin
        },
        layout = wibox.layout.fixed.vertical,
        spacing = 8,
        forced_width = 200
    }
    
    -- Контейнер с фиксированными размерами
    local container = wibox.widget {
        content,
        widget = wibox.container.constraint
    }
    
    self.popup = Popup.new({
        content = container,
        preferred_positions = "bottom",
        preferred_anchors = "back",
        offset = { y = 5 }
    })
    
    -- Проверяем что popup загрузился правильно
    if self.popup and self.popup.on and type(self.popup.on) == "function" then
        -- Включаем события для отслеживания состояния
        self.popup:on("opened", function()
            -- Принудительное обновление виджетов
            self.widget:emit_signal("widget::redraw_needed")
        end)
        
        self.popup:on("closed", function()
            -- Обработка закрытия
        end)
    end
    
    self.popup:bind_to_widget(self.widget)
end

function ControlCenter:_toggle_popup()
    self.popup:toggle()
end

return ControlCenter
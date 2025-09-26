-- ~/.config/awesome/custom/widgets/control_center.lua
local gears = require("gears")
local wibox = require("wibox")
local awful = require("awful")
local beautiful = require("beautiful")

local ControlCenter = {}
ControlCenter.__index = ControlCenter

local Button2 = require("custom.widgets.button_2")
local Text = require("custom.widgets.base_widgets.text")
local Popup = require("custom.widgets.popup")
local Volume = require("custom.widgets.volume")
local Poweroff = require("custom.widgets.poweroff")
local settings = require("custom.settings")

function ControlCenter.new(s)
    local self = setmetatable({}, ControlCenter)
    
    self.screen = s or awful.screen.focused()
    self:_create_widgets()
    
    return self
end

function ControlCenter:_create_widgets()
    -- Получаем цвета из beautiful
    
    -- Кнопка с иконкой awesome
    local control_button = Button2.new({
        content = Text.new({
            text = settings.icons.system.awesome,
            font = settings.fonts.icon .. " 10"
        }),
        width = 26,
        height = 26,
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
            
            button_widget = Button2.new({
                content = layoutbox_widget.widget,
                width = 40,
                height = 40,
                shape = gears.shape.circle
            })
        else
            -- Обычные кнопки
            button_widget = Button2.new({
                content = Text.new({
                    text = button_config.icon,
                    font = settings.fonts.icon .. " 12"
                }),
                width = 40,
                height = 40,
                shape = gears.shape.circle,
                on_click = function()
                    if button_config.command == "wallpaper_selector" then
                        local WallpaperSelector = require("custom.widgets.wallpaper_selector")
                        WallpaperSelector.toggle()
                    elseif button_config.command:match("^awesome%..*") then
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
    
    -- Создаем ряды кнопок по 4 в ряд
    local buttons_rows = {}
    local current_row = {}
    
    for i, widget in ipairs(button_widgets) do
        table.insert(current_row, widget)
        
        -- Когда набралось 4 кнопки или это последняя кнопка
        if #current_row == 4 or i == #button_widgets then
            -- Создаем ряд с равномерным распределением
            local row_widget = wibox.widget {
                layout = wibox.layout.flex.horizontal,
                spacing = 8
            }
            
            for _, btn in ipairs(current_row) do
                row_widget:add(btn)
            end
            
            table.insert(buttons_rows, row_widget)
            current_row = {}
        end
    end
    
    -- Объединяем все ряды
    local buttons_container = wibox.widget {
        layout = wibox.layout.fixed.vertical,
        spacing = 8
    }
    
    for _, row in ipairs(buttons_rows) do
        buttons_container:add(row)
    end
    
    -- Контент popup
    local content = wibox.widget {
        {
            self.volume.widget,
          
            widget = wibox.container.margin
        },
        {
            buttons_container,
            
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
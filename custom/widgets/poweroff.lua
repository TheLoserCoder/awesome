-- ~/.config/awesome/custom/widgets/poweroff.lua
local gears = require("gears")
local wibox = require("wibox")
local awful = require("awful")

local Poweroff = {}
Poweroff.__index = Poweroff

local Button2 = require("custom.widgets.button_2")
local Popup = require("custom.widgets.popup")
local Text = require("custom.widgets.base_widgets.text")
local Container = require("custom.widgets.base_widgets.container")
local settings = require("custom.settings")

function Poweroff.new()
    local self = setmetatable({}, Poweroff)
    
    self:_create_widgets()
    
    return self
end

function Poweroff:_create_widgets()
    local colors = settings.colors
    
    -- Иконка power
    local power_icon = Text.new({
        text = settings.icons.system.power,
        theme_color = "text",
        font = settings.fonts.icon .. " 12"
    })
    
    -- Подпись
    local power_label = Text.new({
        text = "Выключить / Выйти",
        theme_color = "text_secondary",
        font = settings.fonts.main .. " 9"
    })
    
    -- Контент кнопки
    local button_content = wibox.widget {
        power_icon,
        power_label,
        spacing = 4,
        layout = wibox.layout.fixed.horizontal
    }
    
    local power_button = Button2.new({
        content = button_content,
        width = settings.widgets.control_center.width,
        margins = 4,
        on_click = function()
            self:_toggle_popup()
        end
    })
    
    self.widget = power_button.widget
    
    -- Создаем пункты меню
    local menu_items = {
        {text = "Выключить", command = "systemctl poweroff", icon = settings.icons.system.poweroff},
        {text = "Сон", command = "systemctl sleep", icon = settings.icons.system.sleep},
        {text = "Выйти", command = "awesome.quit()", icon = settings.icons.system.logout},
        {text = "Перезагрузить", command = "systemctl reboot", icon = settings.icons.system.reboot},
    }
    
    local menu_layout = wibox.widget {
        layout = wibox.layout.fixed.vertical,
    }
    
    -- Переменные для таймера
    self.countdown_timer = nil
    self.countdown_seconds = 0
    self.selected_command = nil
    self.selected_text = ""
    
    for _, item in ipairs(menu_items) do
        local icon_text = Text.new({
            text = item.icon,
            theme_color = "text",
            font = settings.fonts.icon .. " 12"
        })
        
        local label_text = Text.new({
            text = item.text,
            theme_color = "text",
            font = settings.fonts.main .. " 11"
        })
        
        local menu_button = Button2.new({
            content = wibox.widget {
                icon_text,
                label_text,
                spacing = 8,
                layout = wibox.layout.fixed.horizontal
            },
            width = settings.widgets.control_center.width,
            halign = "left",
            margins = 8,
            on_click = function()
                self:_start_countdown(item.text, item.command)
            end
        })
        menu_layout:add(menu_button.widget)
    end
    
    -- Контент popup без отступов
    local content = Container.new({
        content = menu_layout,
        width = settings.widgets.control_center.width,
        theme_color = "surface"
    })
    
    self.popup = Popup.new({
        content = content,
        margins = 0,
        bg = colors.surface,
        preferred_positions = "bottom",
        preferred_anchors = "front",
        offset = { y = 5 },
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

function Poweroff:_toggle_popup()
    self.popup:toggle()
end

function Poweroff:_start_countdown(text, command)
    self.selected_text = text
    self.selected_command = command
    self.countdown_seconds = 10
    
    -- Создаем контейнер с таймером
    local colors = settings.colors
    
    local countdown_text = Text.new({
        text = text .. " через " .. self.countdown_seconds .. " сек",
        theme_color = "text",
        font = settings.fonts.main .. " 11"
    })
    
    local cancel_button = Button2.new({
        content = Text.new({
            text = "Отмена",
            theme_color = "text",
            font = settings.fonts.main .. " 11"
        }),
        width = settings.widgets.control_center.width / 2 - 4,
        margins = 8,
        on_click = function()
            self:_cancel_countdown()
        end
    })
    
    local now_button = Button2.new({
        content = Text.new({
            text = "Сейчас",
            theme_color = "text",
            font = settings.fonts.main .. " 11"
        }),
        width = settings.widgets.control_center.width / 2 - 4,
        margins = 8,
        on_click = function()
            self:_execute_command()
        end
    })
    
    local countdown_content = wibox.widget {
        {
            countdown_text,
            margins = 8,
            widget = wibox.container.margin
        },
        {
            cancel_button.widget,
            now_button.widget,
            spacing = 8,
            layout = wibox.layout.fixed.horizontal
        },
        layout = wibox.layout.fixed.vertical,
        forced_width = settings.widgets.control_center.width
    }
    
    self.popup:set_content(countdown_content)
    
    -- Запускаем таймер
    self.countdown_timer = gears.timer {
        timeout = 1,
        call_now = false,
        autostart = true,
        callback = function()
            self.countdown_seconds = self.countdown_seconds - 1
            if self.countdown_seconds <= 0 then
                self:_execute_command()
            else
                countdown_text:update_text(text .. " через " .. self.countdown_seconds .. " сек")
            end
        end
    }
end

function Poweroff:_cancel_countdown()
    if self.countdown_timer then
        self.countdown_timer:stop()
        self.countdown_timer = nil
    end
    
    -- Возвращаем исходные кнопки
    local colors = settings.colors
    local menu_items = {
        {text = "Выключить", command = "systemctl poweroff"},
        {text = "Сон", command = "systemctl sleep"},
        {text = "Выйти", command = "awesome.quit()"},
        {text = "Перезагрузить", command = "systemctl reboot"},
    }
    
    local menu_layout = wibox.widget {
        layout = wibox.layout.fixed.vertical,
    }
    
    for _, item in ipairs(menu_items) do
        local menu_button = Button2.new({
            content = Text.new({
                text = item.text,
                theme_color = "text",
                font = settings.fonts.main .. " 11"
            }),
            width = settings.widgets.control_center.width,
            halign = "left",
            margins = 8,
            on_click = function()
                self:_start_countdown(item.text, item.command)
            end
        })
        menu_layout:add(menu_button.widget)
    end
    
    local content = Container.new({
        content = menu_layout,
        width = settings.widgets.control_center.width,
        theme_color = "surface"
    })
    
    self.popup:set_content(content)
end

function Poweroff:_execute_command()
    if self.countdown_timer then
        self.countdown_timer:stop()
        self.countdown_timer = nil
    end
    
    self.popup:hide()
    
    if self.selected_command:match("awesome%.") then
        if self.selected_command == "awesome.quit()" then
            awesome.quit()
        elseif self.selected_command == "awesome.restart()" then
            awesome.restart()
        end
    else
        awful.spawn(self.selected_command)
    end
end

return Poweroff
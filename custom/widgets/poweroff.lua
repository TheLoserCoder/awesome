-- ~/.config/awesome/custom/widgets/poweroff.lua
local gears = require("gears")
local wibox = require("wibox")
local awful = require("awful")

local Poweroff = {}
Poweroff.__index = Poweroff

local Button = require("custom.widgets.button")
local Popup = require("custom.widgets.popup")
local Provider = require("custom.widgets.provider")
local settings = require("custom.settings")

function Poweroff.new()
    local self = setmetatable({}, Poweroff)
    
    self:_create_widgets()
    
    return self
end

function Poweroff:_create_widgets()
    local colors = Provider.get_colors()
    
    -- Иконка power
    local power_icon = wibox.widget {
        text = settings.icons.system.power,
        font = settings.fonts.icon .. " 12",
        align = "center",
        valign = "center",
        fg = colors.text,
        widget = wibox.widget.textbox
    }
    
    -- Подпись
    local power_label = wibox.widget {
        text = "Выключить / Выйти",
        font = settings.fonts.main .. " 9",
        align = "center",
        valign = "center",
        fg = colors.text_secondary,
        widget = wibox.widget.textbox
    }
    
    -- Контент кнопки
    local button_content = wibox.widget {
        {
            power_icon,
            power_label,
            spacing = 4,
            layout = wibox.layout.fixed.horizontal
        },
        margins = 4,
        widget = wibox.container.margin
    }
    
    local power_button = Button.new({
        content = button_content,
        width = settings.widgets.control_center.width,
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
        local menu_button = Button.new({
            content = wibox.widget {
                {
                    {
                        text = item.icon,
                        font = settings.fonts.icon .. " 12",
                        align = "left",
                        widget = wibox.widget.textbox
                    },
                    {
                        text = item.text,
                        font = settings.fonts.main .. " 10",
                        align = "left",
                        widget = wibox.widget.textbox
                    },
                    spacing = 8,
                    layout = wibox.layout.fixed.horizontal
                },
                margins = 8,
                widget = wibox.container.margin
            },
            width = settings.widgets.control_center.width,
            halign = "left",
            on_click = function()
                self:_start_countdown(item.text, item.command)
            end
        })
        menu_layout:add(menu_button.widget)
    end
    
    -- Контент popup без отступов
    local content = wibox.widget {
        menu_layout,
        layout = wibox.layout.fixed.vertical,
        forced_width = settings.widgets.control_center.width
    }
    
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
    local colors = Provider.get_colors()
    
    local countdown_text = wibox.widget {
        text = text .. " через " .. self.countdown_seconds .. " сек",
        font = settings.fonts.main .. " 10",
        align = "center",
        widget = wibox.widget.textbox
    }
    
    local cancel_button = Button.new({
        content = wibox.widget {
            {
                text = "Отмена",
                font = settings.fonts.main .. " 10",
                align = "center",
                widget = wibox.widget.textbox
            },
            margins = 8,
            widget = wibox.container.margin
        },
        width = settings.widgets.control_center.width / 2 - 4,
        on_click = function()
            self:_cancel_countdown()
        end
    })
    
    local now_button = Button.new({
        content = wibox.widget {
            {
                text = "Сейчас",
                font = settings.fonts.main .. " 10",
                align = "center",
                widget = wibox.widget.textbox
            },
            margins = 8,
            widget = wibox.container.margin
        },
        width = settings.widgets.control_center.width / 2 - 4,
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
                countdown_text.text = text .. " через " .. self.countdown_seconds .. " сек"
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
    local colors = Provider.get_colors()
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
        local menu_button = Button.new({
            content = wibox.widget {
                {
                    text = item.text,
                    font = settings.fonts.main .. " 10",
                    align = "left",
                    widget = wibox.widget.textbox
                },
                margins = 8,
                widget = wibox.container.margin
            },
            width = settings.widgets.control_center.width,
            halign = "left",
            on_click = function()
                self:_start_countdown(item.text, item.command)
            end
        })
        menu_layout:add(menu_button.widget)
    end
    
    local content = wibox.widget {
        menu_layout,
        layout = wibox.layout.fixed.vertical,
        forced_width = settings.widgets.control_center.width
    }
    
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
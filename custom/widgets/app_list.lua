-- ~/.config/awesome/custom/widgets/app_list.lua
local gears = require("gears")
local wibox = require("wibox")
local awful = require("awful")

local AppList = {}
AppList.__index = AppList

local Button = require("custom.widgets.button")
local Popup = require("custom.widgets.popup")
local Provider = require("custom.widgets.provider")
local settings = require("custom.settings")

function AppList.new()
    local self = setmetatable({}, AppList)
    
    self.current_client = nil
    self.clients_list = {}
    self:_create_widgets()
    
    -- Отслеживаем изменения
    client.connect_signal("focus", function(c)
        self:_update_display()
    end)
    
    client.connect_signal("unfocus", function(c)
        self:_update_display()
    end)
    
    client.connect_signal("manage", function(c)
        self:_update_display()
    end)
    
    client.connect_signal("unmanage", function(c)
        self:_update_display()
    end)
    
    screen.connect_signal("tag::history::update", function()
        self:_update_display()
    end)
    
    return self
end

function AppList:_create_widgets()
    local colors = Provider.get_colors()
    
    -- Иконка приложения
    self.app_icon = wibox.widget {
        image = nil,
        forced_width = 16,
        forced_height = 16,
        widget = wibox.widget.imagebox
    }
    
    -- Название приложения
    self.app_text = wibox.widget {
        {
            text = "Рабочий стол",
            font = settings.fonts.main .. " 10",
            align = "left",
            valign = "center",
            fg = colors.text,
            ellipsize = "end",
            widget = wibox.widget.textbox
        },
        forced_width = 200,
        widget = wibox.container.constraint
    }
    
    -- Счетчик приложений
    self.app_count = wibox.widget {
        {
            markup = "<span color='" .. colors.surface .. "'>1</span>",
            font = settings.fonts.main .. " 8",
            align = "center",
            valign = "center",
            widget = wibox.widget.textbox
        },
        bg = colors.accent,
        shape = gears.shape.circle,
        forced_width = 16,
        forced_height = 16,
        visible = false,
        widget = wibox.container.background
    }
    
    -- Контент кнопки
    local button_content = wibox.widget {
        self.app_icon,
        self.app_text,
        self.app_count,
        spacing = 6,
        layout = wibox.layout.fixed.horizontal
    }
    
    local app_button = Button.new({
        content = button_content,
        width = 250,
       
        halign = "left",
        on_click = function()
            local clients = self:_get_clients_on_current_tag()
            local total_clients = #clients + (client.focus and 1 or 0)
            
            if total_clients == 0 then
                -- Запускаем лаунчер
                awful.spawn(settings.commands.launcher)
            else
                self:_toggle_popup()
            end
        end
    })
    
    self.widget = app_button.widget
    self.popup_content = wibox.widget {
        spacing = 2,
        layout = wibox.layout.fixed.vertical
    }
    
    self.popup = Popup.new({
        content = self.popup_content,
        margins = 4,
        preferred_positions = "bottom",
        preferred_anchors = "middle",
        offset = { y = 5 }
    })
    
    self.popup:bind_to_widget(self.widget)
    
    -- Начальное обновление
    self:_update_display()
end

function AppList:_get_clients_on_current_tag()
    local clients = {}
    local current_tag = awful.screen.focused().selected_tag
    if not current_tag then return clients end
    
    for _, c in ipairs(current_tag:clients()) do
        if c ~= client.focus then
            table.insert(clients, c)
        end
    end
    return clients
end

function AppList:_update_display()
    local colors = Provider.get_colors()
    local focused = client.focus
    local clients = self:_get_clients_on_current_tag()
    local total_clients = #clients + (focused and 1 or 0)
    
    -- Обновляем главную кнопку
    local text_widget = self.app_text:get_children()[1]
    if total_clients == 0 then
        -- Нет открытых приложений - показываем лаунчер
        self.app_icon.image = nil
        text_widget.align = "center"
        text_widget.markup = "<span color='" .. colors.text .. "'>" .. settings.icons.system.launcher .. " Лаунчер</span>"
    elseif focused then
        self.app_icon.image = focused.icon
        text_widget.align = "left"
        text_widget.text = focused.name or focused.class or "Неизвестно"
    else
        self.app_icon.image = nil
        text_widget.align = "left"
        text_widget.text = "Рабочий стол"
    end
    
    -- Обновляем счетчик
    if total_clients > 1 then
        self.app_count.visible = true
        local count_widget = self.app_count:get_children()[1]
        if count_widget then
            count_widget.markup = "<span color='" .. colors.surface .. "'>" .. tostring(total_clients) .. "</span>"
        end
    else
        self.app_count.visible = false
    end
    
    -- Обновляем список
    self.popup_content:reset()
    
    for _, c in ipairs(clients) do
        local client_button = Button.new({
            content = wibox.widget {
                {
                    image = c.icon,
                    forced_width = 16,
                    forced_height = 16,
                    widget = wibox.widget.imagebox
                },
                {
                    text = c.name or c.class or "Неизвестно",
                    font = settings.fonts.main .. " 10",
                    align = "left",
                    valign = "center",
                    fg = colors.text,
                    ellipsize = "end",
                    widget = wibox.widget.textbox
                },
                spacing = 8,
                layout = wibox.layout.fixed.horizontal
            },
            width = 250,
            height = 28,
            halign = "left",
            on_click = function()
                c:emit_signal("request::activate", "tasklist", {raise = true})
                self.popup:hide()
            end
        })
        
        self.popup_content:add(client_button.widget)
    end
end

function AppList:_toggle_popup()
    local clients = self:_get_clients_on_current_tag()
    if #clients > 0 then
        self.popup:toggle()
    end
end

return AppList
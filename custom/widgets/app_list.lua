-- ~/.config/awesome/custom/widgets/app_list.lua
local gears = require("gears")
local wibox = require("wibox")
local awful = require("awful")
local Container = require("custom.widgets.base_widgets.container")
local AppList = {}
AppList.__index = AppList

local Button2 = require("custom.widgets.button_2")
local Text = require("custom.widgets.base_widgets.text")
local Popup = require("custom.widgets.popup")
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
    local colors = settings.colors
    
    -- Иконка приложения
    self.app_icon = wibox.widget {
        image = nil,
        forced_width = 16,
        forced_height = 16,
        widget = wibox.widget.imagebox
    }
    
    -- Название приложения
    self.app_text_widget = Text.new({
        text = "Рабочий стол",
        font = settings.fonts.main .. " 10"
    })
    
    self.app_text = wibox.widget {
        {
            self.app_text_widget,
            widget = wibox.container.constraint
        },
        forced_width = 200,
        widget = wibox.container.constraint
    }
    
    -- Счетчик приложений
    self.app_count_widget = Text.new({
        text = "1",
        theme_color = "background",
        font = settings.fonts.main .. " 8",
        themed = false
    })
    
  
    local app_count_container = Container.new({
        content = self.app_count_widget,
        theme_color = "accent",
        shape = gears.shape.circle,
        width = 16,
        height = 16
    })
    
    self.app_count = wibox.widget {
        app_count_container,
        widget = wibox.container.background
    }
    
    self.app_count.visible = false
    
    -- Контент кнопки
    local button_content = wibox.widget {
        self.app_icon,
        self.app_text,
        self.app_count,
        spacing = 6,
        layout = wibox.layout.fixed.horizontal
    }
    
    local app_button = Button2.new({
        content = button_content,
        width = 250,
        halign = "left",
        on_click = function()
            self:_toggle_popup()
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
    
    -- Не привязываем popup автоматически, показываем только по клику
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

    local colors = settings.colors
    local focused = client.focus
    local clients = self:_get_clients_on_current_tag()
    local total_clients = #clients + (focused and 1 or 0)
    

    

    
    -- Обновляем главную кнопку
    if focused then
        self.app_icon.image = focused.icon
        self.app_text_widget:update_text(focused.name or focused.class or "Неизвестно")
    else
        self.app_icon.image = nil
        self.app_text_widget:update_text("Рабочий стол")
        -- Принудительно скрываем popup когда нет активного клиента
        if self.popup:get_visible() then
            self.popup:hide()
        end
    end
    
    -- Обновляем счетчик (скрываем если на теге <= 1 окна)
    if total_clients <= 1 then
        self.app_count.visible = false
    else
        self.app_count.visible = true
        self.app_count_widget:update_text(tostring(total_clients))
    end
    
    -- Скрываем popup только если нет клиентов в списке
    if #clients == 0 and self.popup:get_visible() then

        self.popup:hide()
    end
    

    
    -- Обновляем список
    self.popup_content:reset()
    
    for _, c in ipairs(clients) do
        local client_button = Button2.new({
            content = wibox.widget {
                {
                    image = c.icon,
                    forced_width = 16,
                    forced_height = 16,
                    widget = wibox.widget.imagebox
                },
                {
                    {
                        Text.new({
                            text = c.name or c.class or "Неизвестно",
                            font = settings.fonts.main .. " 10"
                        }),
                        widget = wibox.container.constraint
                    },
                    forced_width = 200,
                    widget = wibox.container.constraint
                },
                {
                    Text.new({
                        text = c.minimized and settings.icons.system.window_closed or settings.icons.system.window_open,
                        text_type = c.minimized and "text_muted" or "text",
                        font = settings.fonts.icon
                    }),
                    widget = wibox.container.constraint
                },
                spacing = 6,
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
    local focused = client.focus
    local total_clients = #clients + (focused and 1 or 0)
    

    
    -- Показываем popup только если есть больше одного приложения
    if total_clients > 1 and #clients > 0 then

        self.popup:toggle()
    else

    end
end

return AppList
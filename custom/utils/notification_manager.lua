-- ~/.config/awesome/custom/utils/notification_manager.lua
local naughty = require("naughty")
local gears = require("gears")
local awful = require("awful")
local wibox = require("wibox")
local Provider = require("custom.widgets.provider")
local settings = require("custom.settings")
local WindowFocus = require("custom.utils.window_focus")

local NotificationManager = {}
NotificationManager.__index = NotificationManager

function NotificationManager.new()
    local self = setmetatable({}, NotificationManager)
    
    self.notifications = {}
    self.id_counter = 1
    
    -- Перехватываем стандартные уведомления
    self:_setup_naughty_hook()
    
    -- Отслеживаем urgent окна
    self:_setup_urgent_hook()
    
    return self
end

function NotificationManager:_create_notification_template(n, is_urgent, notification_data)
    local colors = Provider.get_colors()
    local title_text = (n.title and n.title ~= "" and n.title) or ""
    local message_text = (n.text or n.message or "")
    local full_text = title_text .. (title_text ~= "" and message_text ~= "" and ": " or "") .. message_text
    
    local icon_size = is_urgent == "true" and 30 or 16
    
    local notif_buttons = gears.table.join(
        awful.button({}, 1, function()
            if notification_data and notification_data.app_name then
                WindowFocus.focus_by_class(notification_data.app_name)
            end
        end)
    )
    
    local template = {
        {
            {
                {
                    -- Слева иконка
                    {
                        {
                            {
                                image = n.icon,
                                resize = true,
                                forced_width = icon_size,
                                forced_height = icon_size,
                                widget = wibox.widget.imagebox,
                            },
                            shape = function(cr, w, h)
                                gears.shape.rounded_rect(cr, w, h, 8)
                            end,
                            widget = wibox.container.background,
                        },
                        valign = "center",
                        widget = wibox.container.place,
                    },
                    -- Справа текст
                    {
                        {
                            {
                                text = n.app_name or "Application",
                                font = settings.fonts.main .. " Bold 10",
                                fg = colors.accent,
                                ellipsize = "end",
                                widget = wibox.widget.textbox,
                            },
                            {
                                text = full_text,
                                font = settings.fonts.main .. " 9",
                                fg = colors.text_primary,
                                ellipsize = "end",
                                widget = wibox.widget.textbox,
                            },
                            spacing = 2,
                            layout = wibox.layout.fixed.vertical,
                        },
                        valign = "center",
                        widget = wibox.container.place,
                    },
                    spacing = 12,
                    layout = wibox.layout.fixed.horizontal,
                },
                left = 10,
                right = 10,
                top = 5,
                bottom = 5,
                widget = wibox.container.margin,
            },
            valign = "center",
            halign = "left",
            widget = wibox.container.place,
        },
        forced_width = 350,
        forced_height = 60,
        bg = colors.surface,
        shape = function(cr, w, h)
            gears.shape.rounded_rect(cr, w, h, settings.dimensions.corner_radius)
        end,
        widget = wibox.container.background,
        buttons = notif_buttons,
    }
    
    return template
end

function NotificationManager:_setup_naughty_hook()
    local colors = Provider.get_colors()
    
    -- Настраиваем стиль уведомлений
    naughty.config.defaults.bg = colors.surface
    naughty.config.defaults.fg = colors.text_primary
    naughty.config.defaults.border_width = 0
    naughty.config.defaults.shape = function(cr, w, h)
        gears.shape.rounded_rect(cr, w, h, settings.dimensions.corner_radius)
    end
    naughty.config.defaults.margin = 15
    naughty.config.defaults.timeout = settings.widgets.notifications.timeout
    naughty.config.defaults.width = 400
    naughty.config.defaults.height = 80
    naughty.config.defaults.icon_size = 20
    naughty.config.defaults.max_width = 400
    naughty.config.defaults.max_height = 80
    
    -- Настройки для отображения нескольких уведомлений
    naughty.config.spacing = 20
    naughty.config.notification_max = settings.widgets.notifications.max_visible
    
    -- Настройки выравнивания
    naughty.config.defaults.position = "top_middle"
    naughty.config.defaults.font = settings.fonts.main
    
    -- Перехватываем создание уведомлений
    naughty.connect_signal("request::display", function(n)
        -- Сохраняем уведомление в менеджере
        local notification_data = {
            id = self.id_counter,
            title = n.title or "Notification",
            text = n.text or n.message or "",
            icon = n.icon,
            app_name = n.app_name or "Unknown",
            timestamp = os.time(),
            urgency = n.urgency or "normal",
            original = n
        }
        
        self.notifications[self.id_counter] = notification_data
        self.id_counter = self.id_counter + 1
        
        -- Добавляем обработчик для удаления из менеджера
        n:connect_signal("destroyed", function()
            self:remove_notification(notification_data.id)
        end)
        
        -- Эмитируем сигнал о новом уведомлении
        self:emit_signal("notification_added", notification_data)
        
        -- Применяем единый шаблон для обычных уведомлений
        naughty.layout.box { 
            notification = n,
            widget_template = self:_create_notification_template(notification_data, "false", notification_data)
        }
        
        -- Автоматическое исчезновение через 5 секунд
        gears.timer.start_new(5, function()
            if n and not n.is_expired then
                n:destroy()
            end
            return false
        end)
    end)
end

function NotificationManager:_setup_urgent_hook()
    client.connect_signal("property::urgent", function(c)
        if c.urgent then
            local notification_data = {
                id = self.id_counter,
                title = "Urgent Window",
                text = (c.name or "Unknown") .. " requires attention",
                icon = c.icon,
                app_name = c.class or "Unknown",
                timestamp = os.time(),
                urgency = "critical",
                client = c,
                type = "urgent"
            }
            
            self.notifications[self.id_counter] = notification_data
            self.id_counter = self.id_counter + 1
            
            -- Показываем уведомление через naughty в едином стиле
            local n = naughty.notify({
                title = notification_data.title,
                text = notification_data.text,
                icon = notification_data.icon,
                app_name = notification_data.app_name,
                timeout = 0,
                widget_template = self:_create_notification_template(notification_data, "true", notification_data)
            })
            
            -- Обработчик клика
            n:connect_signal("button::press", function()
                self:handle_click(notification_data.id)
            end)
            
            -- Эмитируем сигнал о новом уведомлении
            self:emit_signal("notification_added", notification_data)
        end
    end)
end

function NotificationManager:get_notifications()
    local list = {}
    for id, notification in pairs(self.notifications) do
        table.insert(list, notification)
    end
    
    -- Сортируем по времени (новые сверху)
    table.sort(list, function(a, b)
        return a.timestamp > b.timestamp
    end)
    
    return list
end

function NotificationManager:remove_notification(id)
    if self.notifications[id] then
        local notification = self.notifications[id]
        self.notifications[id] = nil
        self:emit_signal("notification_removed", notification)
        return true
    end
    return false
end

function NotificationManager:clear_all()
    local count = 0
    for id, _ in pairs(self.notifications) do
        count = count + 1
    end
    
    self.notifications = {}
    self:emit_signal("notifications_cleared", count)
    return count
end

function NotificationManager:get_count()
    local count = 0
    for _ in pairs(self.notifications) do
        count = count + 1
    end
    return count
end

function NotificationManager:handle_click(id)
    local notification = self.notifications[id]
    if notification then
        -- Если это urgent окно, переключаемся на него
        if notification.type == "urgent" and notification.client then
            notification.client:jump_to()
            notification.client.urgent = false
        end
        
        -- Удаляем уведомление
        self:remove_notification(id)
        return true
    end
    return false
end

-- События
function NotificationManager:connect_signal(signal_name, callback)
    if not self._signals then
        self._signals = {}
    end
    if not self._signals[signal_name] then
        self._signals[signal_name] = {}
    end
    table.insert(self._signals[signal_name], callback)
end

function NotificationManager:emit_signal(signal_name, ...)
    if self._signals and self._signals[signal_name] then
        for _, callback in ipairs(self._signals[signal_name]) do
            callback(...)
        end
    end
end

-- Создаем единственный экземпляр менеджера
local instance = NotificationManager.new()

-- Отладочное уведомление о создании менеджера

return instance
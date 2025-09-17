-- ~/.config/awesome/custom/utils/notification_manager.lua
local naughty = require("naughty")
local gears = require("gears")
local DebugLogger = require("custom.utils.debug_logger")



local NotificationManager = {}
NotificationManager.__index = NotificationManager

function NotificationManager.new()

    local self = setmetatable({}, NotificationManager)
    
    self.notifications = {}
    self.id_counter = 1
    self.subscribers = {}
    
    self:_setup_hooks()
    
    return self
end

function NotificationManager:_setup_hooks()
    DebugLogger.log("[NOTIFICATION_MANAGER] Setting up hooks")
    
    local manager = self -- Сохраняем ссылку для замыкания
    
    -- Перехватываем создание уведомлений
    naughty.connect_signal("request::display", function(n)
        DebugLogger.log("[NOTIFICATION_MANAGER] request::display triggered: " .. (n.title or "no title"))
        
        manager:_add_notification({
            title = n.title or "Notification",
            text = n.text or n.message or "",
            icon = n.icon,
            app_name = n.app_name or "Unknown",
            urgency = n.urgency or "normal",
            original = n
        })

        n:destroy()
    end)
    
    DebugLogger.log("[NOTIFICATION_MANAGER] request::display hook connected")
    
    -- Отслеживаем urgent окна
    client.connect_signal("property::urgent", function(c)
        if c.urgent and c.valid then
            manager:_add_notification({
                title = "Urgent Window",
                text = (c.name or "Unknown") .. " requires attention",
                icon = c.icon, -- Оставляем как есть
                app_name = c.class or "Unknown",
                urgency = "critical",
                client = nil, -- Не сохраняем ссылку на client
                type = "urgent"
            })
            
            -- Снимаем urgent состояние через 5 секунд
            gears.timer.start_new(5, function()
                if c.valid then
                    c.urgent = false
                end
                return false
            end)
        end
    end)
end

function NotificationManager:_add_notification(data)
    DebugLogger.log("[NOTIFICATION_MANAGER] _add_notification called: " .. (data.title or "no title"))
    
    local notification = {
        id = self.id_counter,
        title = data.title,
        text = data.text,
        icon = data.icon,
        app_name = data.app_name,
        urgency = data.urgency,
        timestamp = os.time(),
        client = data.client,
        type = data.type,
        original = data.original
    }
    
    self.notifications[self.id_counter] = notification
    self.id_counter = self.id_counter + 1
    
    DebugLogger.log("[NOTIFICATION_MANAGER] Added notification with ID: " .. notification.id)
    
    self:_notify_subscribers()
end

function NotificationManager:remove_notification(id)

    if self.notifications[id] then
        self.notifications[id] = nil
        self:_notify_subscribers()
        return true
    end
    return false
end

function NotificationManager:clear_all()
    self.notifications = {}
    self:_notify_subscribers()
end

function NotificationManager:clear_by_app(app_name)
    for id, notification in pairs(self.notifications) do
        if notification.app_name == app_name then
            self.notifications[id] = nil
        end
    end
    self:_notify_subscribers()
end

function NotificationManager:get_notifications()
    local list = {}
    for _, notification in pairs(self.notifications) do
        table.insert(list, notification)
    end
    
    table.sort(list, function(a, b)
        return a.timestamp > b.timestamp
    end)
    
    return list
end

function NotificationManager:subscribe(callback)
    table.insert(self.subscribers, callback)
    -- Немедленно вызываем callback с текущими уведомлениями
    callback(self:get_notifications())
end

function NotificationManager:_notify_subscribers()
    local notifications = self:get_notifications()
    DebugLogger.log("[NOTIFICATION_MANAGER] Notifying " .. #self.subscribers .. " subscribers with " .. #notifications .. " notifications")
    
    for _, callback in ipairs(self.subscribers) do
        callback(notifications)
    end
end

-- Создаем единственный экземпляр менеджера
local instance = NotificationManager.new()

return instance

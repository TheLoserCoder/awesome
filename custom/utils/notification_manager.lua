-- ~/.config/awesome/custom/utils/notification_manager.lua
local naughty = require("naughty")
local gears = require("gears")



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

    local manager = self -- Сохраняем ссылку для замыкания
    
    -- Перехватываем создание уведомлений
    naughty.connect_signal("request::display", function(n)

        manager:_add_notification({
            title = n.title or "Notification",
            text = n.text or n.message or "",
            icon = n.icon,
            app_name = n.app_name or "Unknown",
            urgency = n.urgency or "normal",
            original = n
        })
    end)
    
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
        end
    end)
end

function NotificationManager:_add_notification(data)
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
    for _, callback in ipairs(self.subscribers) do
        callback(notifications)
    end
end

-- Создаем единственный экземпляр менеджера
local instance = NotificationManager.new()

return instance
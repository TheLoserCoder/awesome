-- ~/.config/awesome/custom/widgets/desktop_notifications.lua
local wibox = require("wibox")
local gears = require("gears")
local awful = require("awful")
local Provider = require("custom.widgets.provider")
local settings = require("custom.settings")
local NotificationItem = require("custom.widgets.notification_item")
local WindowFocus = require("custom.utils.window_focus")
local GlobalStorage = require("custom.utils.global_storage")
local NotificationManager = require("custom.utils.notification_manager")

local DesktopNotifications = {}

function DesktopNotifications.setup()
    local colors = Provider.get_colors()
    local active_boxes = {}  -- Список активных wibox'ов
    local last_notification_id = 0
    
    -- Функция для получения базовой позиции
    local function get_base_position()
        local screen_geometry = awful.screen.focused().geometry
        local pos = settings.widgets.desktop_notifications.position
        local margin = settings.widgets.desktop_notifications.margin
        local width = settings.widgets.desktop_notifications.width
        local bar_height = settings.bar.height  -- Высота панели + отступ
        
        if pos == "top_left" then
            return { x = margin, y = bar_height + margin, direction = "down" }
        elseif pos == "top_right" then
            return { x = screen_geometry.width - width - margin, y = bar_height + margin, direction = "down" }
        elseif pos == "bottom_left" then
            return { x = margin, y = screen_geometry.height - margin, direction = "up" }
        elseif pos == "bottom_right" then
            return { x = screen_geometry.width - width - margin, y = screen_geometry.height - margin, direction = "up" }
        elseif pos == "bottom_middle" then
            return { x = (screen_geometry.width - width) / 2, y = screen_geometry.height - margin, direction = "up" }
        else -- top_middle (default)
            return { x = (screen_geometry.width - width) / 2, y = bar_height + margin, direction = "down" }
        end
    end
    
    -- Функция для перепозиционирования всех уведомлений
    local function reposition_notifications()
        local base_pos = get_base_position()
        local offset = 0
        
        for i, box in ipairs(active_boxes) do
            if box.visible then
                local y_pos
                if base_pos.direction == "down" then
                    y_pos = base_pos.y + offset
                else
                    y_pos = base_pos.y - offset - box.height
                end
                
                box.y = y_pos
                offset = offset + box.height + settings.widgets.desktop_notifications.spacing
            end
        end
    end
    
    -- Функция для удаления wibox
    local function remove_wibox(notification_wibox)
        if notification_wibox then
            notification_wibox.visible = false
            -- Удаляем из списка активных
            for i, box in ipairs(active_boxes) do
                if box == notification_wibox then
                    table.remove(active_boxes, i)
                    break
                end
            end
            -- Перепозиционируем оставшиеся уведомления
            reposition_notifications()
        end
    end
    
    -- Функция для удаления всех уведомлений от одного приложения
    local function remove_notifications_by_app(app_name)
        if not app_name then return end
        
        -- Удаляем из активных wibox'ов
        for i = #active_boxes, 1, -1 do
            local box = active_boxes[i]
            if box.notification_data and box.notification_data.app_name == app_name then
                box.visible = false
                table.remove(active_boxes, i)
            end
        end
        
        -- Перепозиционируем оставшиеся
        reposition_notifications()
    end
    
    -- Функция для создания wibox уведомления
    local function create_notification_wibox(notification)
        local item = NotificationItem.new(notification, function(data)
            if notification.type == "urgent" then
                WindowFocus.focus_by_class(data.app_name)
            elseif data.app_name then
                WindowFocus.focus_by_class(data.app_name)
            end
            
            NotificationManager:remove_notification(notification.id)
        end)
        
        local base_pos = get_base_position()
        local offset = 0
        
        -- Получаем размеры notification_item
        local item_width = item.widget.forced_width or settings.widgets.desktop_notifications.width
        local item_height = item.widget.forced_height or 80
        
        -- Новое уведомление всегда появляется сверху (на базовой позиции)
        local y_pos = base_pos.y
        
        local notification_wibox = wibox({
            type = "notification",
            visible = true,
            ontop = true,
            width = item_width,
            height = item_height,
            x = base_pos.x,
            y = y_pos,
            bg = colors.surface,
            shape = function(cr, w, h)
                gears.shape.rounded_rect(cr, w, h, settings.dimensions.corner_radius)
            end,
            widget = item.widget
        })
        
        -- Сохраняем данные уведомления в wibox
        notification_wibox.notification_data = notification
        
        -- Обработчик клика для закрытия всех уведомлений от этого приложения
        notification_wibox:connect_signal("button::press", function()
            remove_notifications_by_app(notification.app_name)
        end)
        
        -- Добавляем в начало списка (новое уведомление сверху)
        table.insert(active_boxes, 1, notification_wibox)
        
        -- Перепозиционируем все уведомления
        reposition_notifications()
        
        -- Автоуничтожение через 5 секунд
        gears.timer.start_new(5, function()
            remove_wibox(notification_wibox)
            return false
        end)
        
        return notification_wibox
    end
    

    
    -- Подписываемся на изменения тихого режима
    GlobalStorage.listen("notifications_disabled", function(is_disabled)
        if is_disabled then
            -- Скрываем все активные уведомления
            for _, box in ipairs(active_boxes) do
                box.visible = false
            end
        end
    end)
    
    -- Подписываемся на уведомления от менеджера
    local DebugLogger = require("custom.utils.debug_logger")
    
    NotificationManager:subscribe(function(notifications)
        DebugLogger.log("[DESKTOP_NOTIFICATIONS] Received " .. (notifications and #notifications or "nil") .. " notifications")
        
        local notifications_disabled = GlobalStorage.get("notifications_disabled") or false
        
        if notifications_disabled then
            DebugLogger.log("[DESKTOP_NOTIFICATIONS] Notifications disabled, skipping")
            return
        end
        
        -- Проверяем есть ли новые уведомления
        if notifications and #notifications > 0 then
            local latest_notification = notifications[1]
            
            DebugLogger.log("[DESKTOP_NOTIFICATIONS] Latest notification ID: " .. (latest_notification and latest_notification.id or "nil") .. ", last_id: " .. last_notification_id)
            
            if latest_notification and latest_notification.id and latest_notification.id > last_notification_id then
                DebugLogger.log("[DESKTOP_NOTIFICATIONS] Creating wibox for notification: " .. (latest_notification.title or "no title"))
                last_notification_id = latest_notification.id
                create_notification_wibox(latest_notification)
            else
                DebugLogger.log("[DESKTOP_NOTIFICATIONS] Notification is not new")
            end
        else
            DebugLogger.log("[DESKTOP_NOTIFICATIONS] No notifications to display")
        end
    end)
    

end

return DesktopNotifications
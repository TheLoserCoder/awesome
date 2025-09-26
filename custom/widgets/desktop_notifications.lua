-- ~/.config/awesome/custom/widgets/desktop_notifications.lua
local wibox = require("wibox")
local gears = require("gears")
local awful = require("awful")
local beautiful = require("beautiful")
local settings = require("custom.settings")
local NotificationItem = require("custom.widgets.notification_item")
local WindowFocus = require("custom.utils.window_focus")
local GlobalStorage = require("custom.utils.global_storage")
local NotificationManager = require("custom.utils.notification_manager")
local DebugLogger = require("custom.utils.debug_logger")

local DesktopNotifications = {}
local active_boxes = {}
local processed_ids = {}

local function get_position()
    local screen_geometry = awful.screen.focused().geometry
    local pos = settings.widgets.desktop_notifications.position
    local margin = settings.widgets.desktop_notifications.margin
    local width = settings.widgets.desktop_notifications.width
    local bar_height = settings.bar.height
    
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
    else
        return { x = (screen_geometry.width - width) / 2, y = bar_height + margin, direction = "down" }
    end
end

local function reposition_all()
    local base_pos = get_position()
    local offset = 0
    
    for _, box in ipairs(active_boxes) do
        if box.visible then
            local y_pos = base_pos.direction == "down" and 
                         (base_pos.y + offset) or 
                         (base_pos.y - offset - box.height)
            box.y = y_pos
            offset = offset + box.height + settings.widgets.desktop_notifications.spacing
        end
    end
end

local function remove_box(target_box)
    target_box.visible = false
    if target_box.timer then
        target_box.timer:stop()
    end
    
    for i, box in ipairs(active_boxes) do
        if box == target_box then
            table.remove(active_boxes, i)
            break
        end
    end
    reposition_all()
end

local function clear_all()
    DebugLogger.log("DESKTOP_NOTIFICATIONS: clearing all notifications, count: " .. #active_boxes)
    
    for _, box in ipairs(active_boxes) do
        box.visible = false
        if box.timer then
            box.timer:stop()
        end
        -- Удаляем из менеджера
        if box.notification_id then
            NotificationManager:remove_notification(box.notification_id)
        end
    end
    
    active_boxes = {}
    processed_ids = {}
    DebugLogger.log("DESKTOP_NOTIFICATIONS: all cleared")
end

local function create_wibox(notification)
    local item = NotificationItem.new(notification, function(data)
        if notification.type == "urgent" then
            WindowFocus.focus_by_class(data.app_name)
        elseif data.app_name then
            WindowFocus.focus_by_class(data.app_name)
        end
        NotificationManager:remove_notification(notification.id)
    end)
    
    local base_pos = get_position()
    local item_width = item.widget.forced_width or settings.widgets.desktop_notifications.width
    local item_height = item.widget.forced_height or 80
    
    local notification_wibox = wibox({
        type = "notification",
        visible = true,
        ontop = true,
        width = item_width,
        height = item_height,
        x = base_pos.x,
        y = base_pos.y,
        bg = beautiful.surface,
        shape = function(cr, w, h)
            gears.shape.rounded_rect(cr, w, h, settings.dimensions.corner_radius)
        end,
        widget = item.widget
    })
    
    notification_wibox.notification_id = notification.id
    
    notification_wibox:connect_signal("button::press", function()
        remove_box(notification_wibox)
    end)
    
    table.insert(active_boxes, 1, notification_wibox)
    reposition_all()
    
    notification_wibox.timer = gears.timer.start_new(5, function()
        NotificationManager:remove_notification(notification.id)
        remove_box(notification_wibox)
        return false
    end)
    
    DebugLogger.log("DESKTOP_NOTIFICATIONS: created wibox for id: " .. notification.id)
end

function DesktopNotifications.setup()
    DebugLogger.log("DESKTOP_NOTIFICATIONS: setup called")
    
    -- Подписка на изменения темы
    local ThemeProvider = require("custom.theme.theme_provider")
    ThemeProvider.get():subscribe(function()
        for _, box in ipairs(active_boxes) do
            if box.visible then
                box.bg = beautiful.surface
            end
        end
    end)
    
    -- Подписка на тихий режим
    GlobalStorage.listen("notifications_disabled", function(disabled)
        if disabled then
            clear_all()
        end
    end)
    
    -- Подписка на центр уведомлений
    GlobalStorage.listen("notification_center_open", function(is_open)
        DebugLogger.log("DESKTOP_NOTIFICATIONS: center open changed to: " .. tostring(is_open))
        if is_open then
            clear_all()
        end
    end)
    
    -- Подписка на уведомления
    NotificationManager:subscribe(function(notifications)
        local disabled = GlobalStorage.get("notifications_disabled")
        local center_open = GlobalStorage.get("notification_center_open")
        
        DebugLogger.log("DESKTOP_NOTIFICATIONS: received notifications, disabled: " .. tostring(disabled) .. ", center_open: " .. tostring(center_open))
        
        if disabled or center_open then
            return
        end
        
        if notifications and #notifications > 0 then
            local latest = notifications[1]
            if latest and latest.id and not processed_ids[latest.id] then
                processed_ids[latest.id] = true
                create_wibox(latest)
            end
        end
    end)
end

return DesktopNotifications
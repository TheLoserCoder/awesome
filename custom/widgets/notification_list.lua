-- ~/.config/awesome/custom/widgets/notification_list.lua
local wibox = require("wibox")
local gears = require("gears")
local awful = require("awful")
local Provider = require("custom.widgets.provider")
local settings = require("custom.settings")
local NotificationManager = require("custom.utils.notification_manager")
local NotificationItem = require("custom.widgets.notification_item")
local WindowFocus = require("custom.utils.window_focus")
local DebugLogger = require("custom.utils.debug_logger")
local GlobalStorage = require("custom.utils.global_storage")

local NotificationList = {}
NotificationList.__index = NotificationList

function NotificationList.new()
    local self = setmetatable({}, NotificationList)
    
    self.container = wibox.widget {
        spacing = settings.widgets.list_item.spacing,
        layout = wibox.layout.fixed.vertical,
    }
    
    self.align_layout = wibox.layout.align.vertical()
    self.align_layout:set_first(self.container)
    
    self.widget = self.align_layout
    self.popup = nil
    self.players_height = 0
    self.scroll_height = 0
    self.cached_items = {}
    
    NotificationManager:subscribe(function(notifications)
        DebugLogger.log("[NOTIFICATION_LIST] Subscribe callback called with " .. #notifications .. " notifications")
        self:_update_list(notifications)
        -- Принудительная перерисовка
        self.widget:emit_signal("widget::layout_changed")
        -- Обновляем кнопку и скролл через notification_center
        if self.notification_center then
            DebugLogger.log("[NOTIFICATION_LIST] Updating notification_center")
            self.notification_center:_update_clear_button_visibility()
            self.notification_center:_update_scroll_height()
        else
            DebugLogger.log("[NOTIFICATION_LIST] notification_center is nil")
        end
    end)
    
    -- Принудительное обновление при создании
    gears.timer.delayed_call(function()
        local notifications = NotificationManager:get_notifications()
        self:_update_list(notifications)
    end)
    -- Обновляем время при открытии центра уведомлений
    GlobalStorage.listen("notification_center_open", function(is_open)
        DebugLogger.log("[NOTIFICATION_LIST] notification_center_open event: " .. tostring(is_open))
        if is_open then
            self:update_times()
        end
    end)
    
    return self
end

function NotificationList:_update_list(notifications)
    -- Создаем маппу текущих ID
    local current_ids = {}
    for _, notification in ipairs(notifications) do
        current_ids[notification.id] = true
    end
    
    -- Удаляем виджеты, которых нет в текущем списке
    for id, item in pairs(self.cached_items) do
        if not current_ids[id] then
            self.container:remove_widgets(item.widget)
            self.cached_items[id] = nil
        end
    end
    
    if #notifications == 0 then
        if not self.empty_widget then
            local colors = Provider.get_colors()
            
            local empty_message = wibox.widget {
                {
                    text = "Нет уведомлений",
                    font = settings.fonts.main .. " 10",
                    fg = colors.text_secondary,
                    align = "center",
                    valign = "center",
                    widget = wibox.widget.textbox,
                },
                margins = 15,
                widget = wibox.container.margin,
            }
            
            local background_widget = wibox.widget {
                empty_message,
                bg = colors.surface,
                shape = gears.shape.rounded_rect,
                widget = wibox.container.background,
            }
            
            self.empty_widget = wibox.widget {
                {
                    background_widget,
                    valign = "center",
                    halign = "center",
                    widget = wibox.container.place,
                },
                widget = wibox.container.constraint,
            }
        end
        
        local container_height = self.scroll_height - self.players_height
        self.empty_widget.forced_height = container_height
        self.align_layout:set_second(self.empty_widget)
    else
        self.align_layout:set_second(nil)
        
        -- Добавляем новые виджеты в правильном порядке
        for i, notification in ipairs(notifications) do
            if not self.cached_items[notification.id] then
                self.cached_items[notification.id] = NotificationItem.new(notification, function(data)
                    if data.app_name then
                        WindowFocus.focus_by_class(data.app_name)
                        NotificationManager:clear_by_app(data.app_name)
                    else
                        NotificationManager:remove_notification(data.id)
                    end
                    
                    if self.popup then
                        self.popup:hide()
                    end
                end)
                
                -- Вставляем в правильное место
                self.container:insert(i, self.cached_items[notification.id].widget)
            end
        end
    end
end

function NotificationList:refresh()
    local notifications = NotificationManager:get_notifications()
    self:_update_list(notifications)
end

function NotificationList:set_popup(popup)
    self.popup = popup
end

function NotificationList:set_dimensions(players_height, scroll_height)
    self.players_height = players_height
    self.scroll_height = scroll_height
end

function NotificationList:update_times()
    local count = 0
    for _ in pairs(self.cached_items) do count = count + 1 end
    DebugLogger.log("[NOTIFICATION_LIST] Updating times for " .. count .. " items")
    
    for _, item in pairs(self.cached_items) do
        if item.update_time then
            item:update_time()
        end
    end
    
    -- Принудительное обновление виджетов
    self.widget:emit_signal("widget::layout_changed")
end

function NotificationList:set_notification_center(notification_center)
    self.notification_center = notification_center
end

return NotificationList
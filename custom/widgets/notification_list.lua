-- ~/.config/awesome/custom/widgets/notification_list.lua
local wibox = require("wibox")
local gears = require("gears")
local awful = require("awful")
local Provider = require("custom.widgets.provider")
local settings = require("custom.settings")
local NotificationManager = require("custom.utils.notification_manager")
local NotificationItem = require("custom.widgets.notification_item")
local WindowFocus = require("custom.utils.window_focus")


local NotificationList = {}
NotificationList.__index = NotificationList

function NotificationList.new()

    local self = setmetatable({}, NotificationList)
    local colors = Provider.get_colors()
    
    -- Создаем контейнер для уведомлений
    self.container = wibox.widget {
        spacing = 8,
        layout = wibox.layout.fixed.vertical,
    }
    
    -- Основной виджет с растягивающимся контейнером для плашки
    self.align_layout = wibox.layout.align.vertical()
    self.align_layout:set_first(self.container)
    
    self.widget = wibox.widget {
        self.align_layout,
        layout = wibox.layout.fixed.vertical,
    }
    
    -- Подписываемся на обновления уведомлений
    NotificationManager:subscribe(function(notifications)
        self:_update_list(notifications)
    end)
    
    return self
end

function NotificationList:_update_list(notifications)
    self.container:reset()
    
    if #notifications == 0 then
        local colors = Provider.get_colors()
        
        -- Плашка с уменьшенным фоном
        local empty_message = wibox.widget {
            {
                text = "Нет уведомлений",
                font = settings.fonts.main .. " 10",
                fg = colors.text_secondary,
                align = "center",
                valign = "center",
                widget = wibox.widget.textbox,
            },
            margins = 5,
            widget = wibox.container.margin,
        }
        
        local background_widget = wibox.widget {
            empty_message,
            forced_height = 500,
            widget = wibox.container.background,
        }
        
        -- Очищаем список и добавляем плашку в среднюю секцию
        self.container:reset()
        
        -- Обновляем среднюю секцию
        self.align_layout:set_second(wibox.widget {
            background_widget,
            valign = "center",
            halign = "center",
            widget = wibox.container.place,
        })
        

    else
        -- Очищаем среднюю секцию (плашка не нужна)
        self.align_layout:set_second(nil)
        
        for _, notification in ipairs(notifications) do
            local item = NotificationItem.new(notification, function(data)
                -- При клике переходим к окну, очищаем уведомления и закрываем popup
                if data.app_name then
                    WindowFocus.focus_by_class(data.app_name)
                    -- Очищаем все уведомления от этого приложения
                    NotificationManager:clear_by_app(data.app_name)
                else
                    -- Если нет app_name, удаляем только это уведомление
                    NotificationManager:remove_notification(data.id)
                end
                
                -- Закрываем popup
                if self.popup then
                    self.popup:hide()
                end
            end)
            
            self.container:add(item.widget)
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

return NotificationList
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
    
    -- Основной виджет (без заголовка, прозрачный фон)
    self.widget = wibox.widget {
        {
            self.container,
            forced_height = 300,
            bg = "transparent", -- Прозрачный фон
            widget = wibox.container.background,
        },
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
        
        -- Плашка с фоном
        local empty_message = wibox.widget {
            {
                text = "Нет уведомлений",
                font = settings.fonts.main .. " 10",
                fg = colors.text_secondary,
                align = "center",
                valign = "center",
                widget = wibox.widget.textbox,
            },
            margins = 20,
            widget = wibox.container.margin,
        }
        
        local background_widget = wibox.widget {
            empty_message,
            bg = colors.surface,
            shape = function(cr, w, h)
                gears.shape.rounded_rect(cr, w, h, settings.dimensions.corner_radius)
            end,
            widget = wibox.container.background,
        }
        
        -- Центрируем в контейнере
        self.container:add(wibox.widget {
            {
                background_widget,
                valign = "center",
                halign = "center",
                widget = wibox.container.place,
            },
            forced_height = 300,
            widget = wibox.container.constraint,
        })
    else
        for _, notification in ipairs(notifications) do
            local item = NotificationItem.new(notification, function(data)
                -- При клике переходим к окну и удаляем уведомление
                if data.app_name then
                    WindowFocus.focus_by_class(data.app_name)
                end
                NotificationManager:remove_notification(data.id)
            end)
            
            self.container:add(item.widget)
        end
    end
end

function NotificationList:refresh()
    local notifications = NotificationManager:get_notifications()
    self:_update_list(notifications)
end

return NotificationList
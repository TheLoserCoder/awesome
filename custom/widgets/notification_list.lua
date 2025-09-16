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
    
    -- Заголовок с кнопкой очистки
    local header = wibox.widget {
        {
            text = "Уведомления",
            font = settings.fonts.main .. " Bold 12",
            fg = colors.text_primary,
            widget = wibox.widget.textbox,
        },
        {
            text = "Очистить",
            font = settings.fonts.main .. " 9",
            fg = colors.accent,
            buttons = gears.table.join(
                awful.button({}, 1, function()
                    NotificationManager:clear_all()
                end)
            ),
            widget = wibox.widget.textbox,
        },
        layout = wibox.layout.align.horizontal,
    }
    
    -- Основной виджет
    self.widget = wibox.widget {
        header,
        {
            self.container,
            forced_height = 300,
            bg = colors.surface,
            widget = wibox.container.background,
        },
        spacing = 10,
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
        self.container:add(wibox.widget {
            {
                text = "Нет уведомлений",
                font = settings.fonts.main .. " 9",
                fg = colors.text_secondary,
                align = "center",
                widget = wibox.widget.textbox,
            },
            forced_height = 40,
            valign = "center",
            widget = wibox.container.place,
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
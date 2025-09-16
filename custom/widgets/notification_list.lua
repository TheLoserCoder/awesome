-- ~/.config/awesome/custom/widgets/notification_list.lua
local wibox = require("wibox")
local gears = require("gears")
local awful = require("awful")
local Provider = require("custom.widgets.provider")
local settings = require("custom.settings")
local NotificationManager = require("custom.utils.notification_manager")
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
            forced_height = 200,
            step_function = wibox.container.scroll.step_functions.waiting_nonlinear_back_and_forth,
            speed = 50,
            widget = wibox.container.scroll.vertical,
        },
        spacing = 10,
        layout = wibox.layout.fixed.vertical,
    }
    
    return self
end

function NotificationList:_create_notification_item(notification)
    local colors = Provider.get_colors()
    
    local notif_buttons = gears.table.join(
        awful.button({}, 1, function()
            if notification.app_name then
                WindowFocus.focus_by_class(notification.app_name)
            end
        end)
    )
    
    return wibox.widget {
        {
            {
                {
                    -- Иконка
                    notification.icon and {
                        {
                            {
                                image = notification.icon,
                                resize = true,
                                forced_width = 24,
                                forced_height = 24,
                                widget = wibox.widget.imagebox,
                            },
                            shape = function(cr, w, h)
                                gears.shape.rounded_rect(cr, w, h, 8)
                            end,
                            widget = wibox.container.background,
                        },
                        valign = "center",
                        widget = wibox.container.place,
                    } or {
                        {
                            text = "🔔",
                            font = "16",
                            align = "center",
                            valign = "center",
                            forced_width = 24,
                            forced_height = 24,
                            widget = wibox.widget.textbox,
                        },
                        valign = "center",
                        widget = wibox.container.place,
                    },
                    -- Текст
                    {
                        {
                            {
                                text = notification.app_name or "Application",
                                font = settings.fonts.main .. " Bold 10",
                                fg = colors.accent,
                                ellipsize = "end",
                                widget = wibox.widget.textbox,
                            },
                            {
                                text = notification.text or notification.title or "",
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
        forced_height = 50,
        bg = colors.surface,
        shape = function(cr, w, h)
            gears.shape.rounded_rect(cr, w, h, settings.dimensions.corner_radius)
        end,
        widget = wibox.container.background,
        buttons = notif_buttons,
    }
end

function NotificationList:refresh()

    
    local notifications = NotificationManager:get_notifications()
    
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
            self.container:add(self:_create_notification_item(notification))
        end
    end
end

return NotificationList
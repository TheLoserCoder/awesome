-- ~/.config/awesome/custom/widgets/notification_item.lua
local wibox = require("wibox")
local gears = require("gears")
local awful = require("awful")
local Provider = require("custom.widgets.provider")
local settings = require("custom.settings")
local IconCache = require("custom.utils.icon_cache")
local Button = require("custom.widgets.button")



local NotificationItem = {}
NotificationItem.__index = NotificationItem

function NotificationItem.new(notification_data, on_click)
    local self = setmetatable({}, NotificationItem)
    

    
    local colors = Provider.get_colors()

    
    -- Размеры иконок
    local container_size = 50 -- Единый размер контейнера
    local icon_size = (notification_data.type == "urgent") and 16 or 50 -- Размер самой иконки
    
    -- Создаем содержимое уведомления
    local content = wibox.widget {
        {
            {
                -- Иконка с проверкой
                (function()
                    local icon = notification_data.icon

                    
                    -- Пробуем получить путь к иконке (конвертируем userdata в PNG)
                    local icon_path = IconCache.get_icon_path(icon, notification_data.app_name)
                    
                    if icon_path then
                        local success, result = pcall(function()
                            return {
                                {
                                    {
                                        image = icon_path,
                                        resize = true,
                                        forced_width = icon_size,
                                        forced_height = icon_size,
                                        widget = wibox.widget.imagebox,
                                    },
                                    valign = "center",
                                    halign = "center",
                                    widget = wibox.container.place,
                                },
                                forced_width = container_size,
                                forced_height = container_size,
                                shape = function(cr, w, h)
                                    gears.shape.rounded_rect(cr, w, h, 8)
                                end,
                                widget = wibox.container.background,
                            }
                        end)
                        
                        if success then
                            return result
                        end
                    end
                    
                    -- Фолбэк иконка
                    return {
                        {
                            text = settings.widgets.notifications.default_icon,
                            font = settings.fonts.icon,
                            align = "center",
                            valign = "center",
                            fg = colors.accent,
                            widget = wibox.widget.textbox,
                        },
                        forced_width = container_size,
                        forced_height = container_size,
                        shape = function(cr, w, h)
                            gears.shape.rounded_rect(cr, w, h, 8)
                        end,
                        widget = wibox.container.background,
                    }
                end)(),
                -- Текст
                {
                    {
                        {
                            text = notification_data.app_name or "Application",
                            font = settings.fonts.main .. " Bold 10",
                            fg = colors.accent,
                            ellipsize = "end",
                            widget = wibox.widget.textbox,
                        },
                        {
                            text = notification_data.text or notification_data.title or "",
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
    }
    
    -- Оборачиваем в Button со стандартными цветами
    local button = Button.new({
        content = content,
        width = 350,
        height = 60,
        halign = "left", -- Выравнивание по левому краю
        valign = "center",
        margins = 0, -- Убираем padding
        on_click = function()
            if on_click then
                on_click(notification_data)
            end
        end
    })
    
    self.widget = button.widget
    

    return self
end

return NotificationItem
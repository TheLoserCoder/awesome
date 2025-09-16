-- ~/.config/awesome/custom/widgets/notification_item.lua
local wibox = require("wibox")
local gears = require("gears")
local awful = require("awful")
local Provider = require("custom.widgets.provider")
local settings = require("custom.settings")
local IconCache = require("custom.utils.icon_cache")



local NotificationItem = {}
NotificationItem.__index = NotificationItem

function NotificationItem.new(notification_data, on_click)
    local self = setmetatable({}, NotificationItem)
    

    
    local colors = Provider.get_colors()

    
    local icon_size = 16
    
    local notif_buttons = gears.table.join(
        awful.button({}, 1, function()
            if on_click then
                on_click(notification_data)
            end
        end)
    )
    
    self.widget = wibox.widget {
        {
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
                                        image = icon_path,
                                        resize = true,
                                        forced_width = icon_size,
                                        forced_height = icon_size,
                                        widget = wibox.widget.imagebox,
                                    },
                                    valign = "center",
                                    widget = wibox.container.place,
                                }
                            end)
                            
                            if success then
                                return result
                            end
                        end
                        
                        -- Фолбэк иконка
                        return {
                            text = settings.widgets.notifications.default_icon,
                            font = settings.fonts.icon,
                            align = "center",
                            valign = "center",
                            forced_width = icon_size,
                            forced_height = icon_size,
                            fg = colors.accent,
                            widget = wibox.widget.textbox,
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
        },
        forced_height = 60,
        bg = colors.surface,
        shape = function(cr, w, h)
            gears.shape.rounded_rect(cr, w, h, settings.dimensions.corner_radius)
        end,
        widget = wibox.container.background,
        buttons = notif_buttons,
    }
    

    return self
end

return NotificationItem
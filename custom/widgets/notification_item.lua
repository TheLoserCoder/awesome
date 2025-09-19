-- ~/.config/awesome/custom/widgets/notification_item.lua
local wibox = require("wibox")
local gears = require("gears")
local awful = require("awful")
local Provider = require("custom.widgets.provider")
local settings = require("custom.settings")
local IconCache = require("custom.utils.icon_cache")
local Button = require("custom.widgets.button")
local DebugLogger = require("custom.utils.debug_logger")



local NotificationItem = {}
NotificationItem.__index = NotificationItem

-- Функция для форматирования времени
local function format_time(timestamp)
    local current_time = os.time()
    local diff = current_time - timestamp
    
    if diff < 3600 then -- Меньше 1 часа
        local minutes = math.floor(diff / 60)
        if minutes < 1 then
            return "сейчас"
        else
            return minutes .. "м"
        end
    else
        return os.date("%H:%M", timestamp)
    end
end

function NotificationItem.new(notification_data, on_click, height)
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
                            {
                                text = notification_data.app_name or "Application",
                                font = settings.fonts.main .. " Bold 10",
                                fg = colors.accent,
                                ellipsize = "end",
                                widget = wibox.widget.textbox,
                            },
                            {
                                (function()
                                    local time_widget = wibox.widget {
                                        markup = '<span color="#6C7086">' .. format_time(notification_data.timestamp) .. '</span>',
                                        font = settings.fonts.main .. " 9",
                                        widget = wibox.widget.textbox,
                                    }
                                    self.time_widget = time_widget
                                    self.timestamp = notification_data.timestamp
                                    return time_widget
                                end)(),
                                valign = "center",
                                widget = wibox.container.place
                            },
                            spacing = 8,
                            layout = wibox.layout.fixed.horizontal,
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
        height = height or settings.widgets.list_item.height,
        halign = "left",
        valign = "center",
        margins = 0,
        on_click = function()
            if on_click then
                on_click(notification_data)
            end
        end
    })
    
    self.widget = button.widget
    
    return self
end

function NotificationItem:update_time()
    if self.time_widget and self.timestamp then
        local new_time = format_time(self.timestamp)
        DebugLogger.log("[NotificationItem] Updating time from " .. (self.time_widget.text or "nil") .. " to " .. new_time)
        self.time_widget.markup = '<span color="#6C7086">' .. new_time .. '</span>'
    end
end

return NotificationItem
-- ~/.config/awesome/custom/widgets/notification_item.lua
local wibox = require("wibox")
local gears = require("gears")
local awful = require("awful")
local beautiful = require("beautiful")
local settings = require("custom.settings")
local IconCache = require("custom.utils.icon_cache")
local Button2 = require("custom.widgets.button_2")
local Text = require("custom.widgets.base_widgets.text")
local Container = require("custom.widgets.base_widgets.container")




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
    -- Используем beautiful для получения цветов из темы
    
    -- Создаем виджеты
    local app_name = Text.new({
        text = notification_data.app_name or "Application",
        font = settings.fonts.main .. " Bold 10",
        color = beautiful.accent
    })
    
    self.time_widget = Text.new({
        text = format_time(notification_data.timestamp),
        theme_color = "text_muted",
        font = settings.fonts.main .. " 9"
    })
    self.timestamp = notification_data.timestamp
    
    local message = Text.new({
        text = notification_data.text or notification_data.title or "",
        font = settings.fonts.main .. " 9"
    })
    
    -- Иконка с размером в зависимости от типа
    local icon_size = (notification_data.type == "urgent") and 16 or 50
    local icon_widget = wibox.widget {
        {
            {
                {
                    image = nil,
                    forced_width = icon_size,
                    forced_height = icon_size,
                    widget = wibox.widget.imagebox
                },
                shape = function(cr, w, h) gears.shape.rounded_rect(cr, w, h, 8) end,
                clip = true,
                widget = wibox.container.background
            },
            halign = "center",
            valign = "center",
            widget = wibox.container.place
        },
        forced_width = 50,
        forced_height = 50,
        widget = wibox.container.constraint
    }
    
    -- Пробуем установить иконку
    local icon_path = IconCache.get_icon_path(notification_data.icon, notification_data.app_name)
    if icon_path then
        icon_widget:get_children()[1]:get_children()[1]:get_children()[1].image = icon_path
    end
    
    -- Layout с иконкой
    local content = wibox.widget {
        {
            {
                icon_widget,
                valign = "center",
                widget = wibox.container.place
            },
            {
                {
                    {
                        app_name,
                        self.time_widget,
                        spacing = 8,
                        layout = wibox.layout.fixed.horizontal
                    },
                    message,
                    spacing = 4,
                    layout = wibox.layout.fixed.vertical
                },
                valign = "center",
                halign = "left",
                widget = wibox.container.place
            },
            spacing = 8,
            layout = wibox.layout.fixed.horizontal
        },
        margins = 4,
        widget = wibox.container.margin
    }
    
    local button = Button2.new({
        content = content,
        width = 350,
        height = height or settings.widgets.list_item.height,
        halign = "left",
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
        self.time_widget:update_text(new_time)
    end
end

return NotificationItem
-- ~/.config/awesome/custom/widgets/desktop_notifications.lua
local naughty = require("naughty")
local gears = require("gears")
local Provider = require("custom.widgets.provider")
local settings = require("custom.settings")
local NotificationItem = require("custom.widgets.notification_item")
local WindowFocus = require("custom.utils.window_focus")

local DesktopNotifications = {}

function DesktopNotifications.setup()
    local colors = Provider.get_colors()
    
    -- Настраиваем стиль уведомлений
    naughty.config.defaults.bg = colors.surface
    naughty.config.defaults.fg = colors.text_primary
    naughty.config.defaults.border_width = 0
    naughty.config.defaults.shape = function(cr, w, h)
        gears.shape.rounded_rect(cr, w, h, settings.dimensions.corner_radius)
    end
    naughty.config.defaults.margin = 15
    naughty.config.defaults.timeout = settings.widgets.notifications.timeout
    naughty.config.defaults.width = 400
    naughty.config.defaults.height = 80
    naughty.config.defaults.icon_size = 20
    naughty.config.defaults.max_width = 400
    naughty.config.defaults.max_height = 80
    naughty.config.spacing = 20
    naughty.config.notification_max = settings.widgets.notifications.max_visible
    naughty.config.defaults.position = "top_middle"
    naughty.config.defaults.font = settings.fonts.main
    
    -- Перехватываем создание уведомлений для отображения на рабочем столе
    naughty.connect_signal("request::display", function(n)
        local notification_data = {
            title = n.title or "Notification",
            text = n.text or n.message or "",
            icon = n.icon,
            app_name = n.app_name or "Unknown",
            urgency = n.urgency or "normal"
        }
        
        -- Создаем виджет уведомления с обработчиком клика
        local item = NotificationItem.new(notification_data, function(data)
            if data.app_name then
                WindowFocus.focus_by_class(data.app_name)
            end
            n:destroy()
        end)
        
        -- Применяем шаблон
        naughty.layout.box { 
            notification = n,
            widget_template = item.widget
        }
        
        -- Автоматическое исчезновение через 5 секунд
        if n.urgency ~= "critical" then
            gears.timer.start_new(5, function()
                if n and not n.is_expired then
                    n:destroy()
                end
                return false
            end)
        end
    end)
end

return DesktopNotifications
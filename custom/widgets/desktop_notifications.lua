-- ~/.config/awesome/custom/widgets/desktop_notifications.lua
local naughty = require("naughty")
local wibox = require("wibox")
local gears = require("gears")
local Provider = require("custom.widgets.provider")
local settings = require("custom.settings")
local NotificationItem = require("custom.widgets.notification_item")
local WindowFocus = require("custom.utils.window_focus")
local GlobalStorage = require("custom.utils.global_storage")

local DesktopNotifications = {}

DesktopNotifications.notification_center_open = false;

function DesktopNotifications.setup()
    local colors = Provider.get_colors()
    
    -- Локальная переменная для отслеживания состояния центра

    -- Подписываемся на изменения глобального состояния
    GlobalStorage.listen("notification_center_open", function(is_open)
      DesktopNotifications.notification_center_open = is_open
        
        -- Если центр открылся, скрываем все активные уведомления
        if is_open then
            for _, notification in pairs(naughty.active) do
                notification:destroy()
            end
        end
    end)
    
    -- Настраиваем стиль уведомлений
    naughty.config.defaults.bg = "transparent" -- Прозрачный фон
    naughty.config.defaults.fg = colors.text_primary
    naughty.config.defaults.border_width = 0
    -- Не задаем shape - его задает кнопка
    naughty.config.defaults.margin = 10
    naughty.config.defaults.timeout = settings.widgets.notifications.timeout
    naughty.config.defaults.width = 350
    naughty.config.defaults.height = 70
    naughty.config.defaults.icon_size = 20
    naughty.config.defaults.max_width = 350
    naughty.config.defaults.max_height = 60
    naughty.config.spacing = 20
    naughty.config.notification_max = settings.widgets.notifications.max_visible
    naughty.config.defaults.position = "top_middle"
    naughty.config.defaults.font = settings.fonts.main
    
    -- Перехватываем создание уведомлений для отображения на рабочем столе
    naughty.connect_signal("request::display", function(n)
        -- Проверяем локальную переменную
        if DesktopNotifications.notification_center_open then
            -- Если центр открыт, не показываем desktop уведомления
            return
        end
        
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
        
        -- Применяем шаблон с разными цветами для отслеживания
        naughty.layout.box { 
            notification = n,
            widget_template = {
                {
                    item.widget,
                    forced_width = 350,
                    forced_height = 60,
                    bg = "transparent", -- Прозрачный фон
                    widget = wibox.container.constraint
                },
                bg = colors.surface, -- Стандартный фон кнопки
                widget = wibox.container.background
            }
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
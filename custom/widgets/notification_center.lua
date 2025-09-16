-- ~/.config/awesome/custom/widgets/notification_center.lua
local gears = require("gears")
local wibox = require("wibox")
local awful = require("awful")
local NotificationCenter = {}
NotificationCenter.__index = NotificationCenter

-- Получаем зависимости
local Button = require("custom.widgets.button")
local Popup = require("custom.widgets.popup")
local PlayersList = require("custom.widgets.players_list")
local NotificationList = require("custom.widgets.notification_list")
local Clock = require("custom.widgets.clock")
local settings = require("custom.settings")


-- Создание виджета центра уведомлений
function NotificationCenter.new(config)

    config = config or {}
    local self = setmetatable({}, NotificationCenter)
    
    self:_create_widgets()
    self.popup:bind_to_widget(self.widget)
    
    return self
end

-- Создание виджетов
function NotificationCenter:_create_widgets()

    -- Кнопка в виде часов
    self.clock = Clock.new()
    self.widget = wibox.widget {
        self.clock.widget,
        buttons = gears.table.join(
            awful.button({}, 1, function()
                self:_toggle_popup()
            end)
        ),
        widget = wibox.container.background,
    }
    
    -- Создаем списки
    self.players_list = PlayersList.new()

    self.notification_list = NotificationList.new()

    
    -- Контейнер с содержимым
    local content = wibox.widget {
        {
            text = "Плееры",
            font = settings.fonts.main .. " Bold 14",
            widget = wibox.widget.textbox,
        },
        self.players_list.widget,
        {
            widget = wibox.widget.separator,
            orientation = "horizontal",
            forced_height = 1,
            color = "#444444",
        },
        self.notification_list.widget,
        spacing = 15,
        layout = wibox.layout.fixed.vertical,
    }
    
    -- Контейнер с фиксированной шириной
    local container = wibox.widget {
        content,
        forced_width = 350,
        widget = wibox.container.constraint
    }
    
    self.popup = Popup.new({
        content = container,
        width = 350,
        height = 500
    })
    
    -- Передаем ссылку на popup в PlayersList
    self.players_list:set_popup(self.popup)
end

-- Переключение popup
function NotificationCenter:_toggle_popup()

    if not self.popup.visible then
        self.players_list:refresh()

        self.notification_list:refresh()

    end
    self.popup:toggle()
end

return NotificationCenter
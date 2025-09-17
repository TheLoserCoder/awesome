-- ~/.config/awesome/custom/widgets/notification_center.lua
local gears = require("gears")
local wibox = require("wibox")
local awful = require("awful")
local NotificationCenter = {}
NotificationCenter.__index = NotificationCenter

-- Безопасное подключение зависимостей
local SafeRequire = require("custom.utils.safe_require")
local Button = SafeRequire.require("custom.widgets.button")
local Popup = SafeRequire.require("custom.widgets.popup")
local PlayersList = SafeRequire.require("custom.widgets.players_list")
local NotificationList = SafeRequire.require("custom.widgets.notification_list")
local Clock = SafeRequire.require("custom.widgets.clock")
local NotificationManager = SafeRequire.require("custom.utils.notification_manager")
local GlobalStorage = SafeRequire.require("custom.utils.global_storage")
local settings = SafeRequire.require("custom.settings")


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

    -- Оборачиваем только виджет часов в Button
    self.clock = Clock.new()
    local clock_button = Button.new({
        content = self.clock.widget,
        width = 80,  -- Указываем размеры как в players_center
        height = 24,
    
        on_click = function()
            self:_toggle_popup()
        end
    })
    self.widget = clock_button.widget
    
    -- Создаем списки
    self.players_list = PlayersList.new()

    self.notification_list = NotificationList.new()

    
    -- Кнопка очистки уведомлений
    local clear_button = Button.new({
        content = wibox.widget {
            text = "Очистить уведомления",
            font = settings.fonts.main .. " 10",
            align = "center",
            widget = wibox.widget.textbox,
        },
        height = 35,
        on_click = function()
            NotificationManager:clear_all()
        end
    })
    
    -- Контейнер с содержимым (без заголовков)
    local content = wibox.widget {
        -- Плееры (без фиксированного размера)
        self.players_list.widget,
        {
            widget = wibox.widget.separator,
            orientation = "horizontal",
            forced_height = 1,
            color = "#444444",
        },
        -- Уведомления
        self.notification_list.widget,
        -- Кнопка очистки внизу
        clear_button.widget,
        spacing = 15,
        layout = wibox.layout.fixed.vertical,
    }
    
    -- Контейнер с фиксированной шириной
    local container = wibox.widget {
        content,
        forced_width = 350,
        widget = wibox.container.constraint
    }
    
    -- Отладка: проверяем что загрузилось
    local naughty = require("naughty")
    naughty.notify({
        title = "Popup Debug",
        text = "Popup type: " .. type(Popup) .. "\nPopup.new type: " .. type(Popup.new),
        timeout = 5
    })
    
    self.popup = Popup.new({
        content = container,
        width = 350,
        height = 500
    })
    
    naughty.notify({
        title = "Popup Instance Debug",
        text = "popup type: " .. type(self.popup) .. "\npopup.on type: " .. type(self.popup.on),
        timeout = 5
    })
    
    -- Проверяем что popup загрузился правильно
    if self.popup and self.popup.on and type(self.popup.on) == "function" then
        -- Включаем события для отслеживания состояния
        self.popup:on("opened", function()
            if self.players_list and self.players_list.refresh then
                self.players_list:refresh()
            end
            if self.notification_list and self.notification_list.refresh then
                self.notification_list:refresh()
            end
            if GlobalStorage and GlobalStorage.set then
                GlobalStorage.set("notification_center_open", true)
            end
        end)
        
        self.popup:on("closed", function()
            if GlobalStorage and GlobalStorage.set then
                GlobalStorage.set("notification_center_open", false)
            end
        end)
    end
    
    -- Передаем ссылку на popup в PlayersList
    self.players_list:set_popup(self.popup)
end

-- Переключение popup
function NotificationCenter:_toggle_popup()
    self.popup:toggle()
end

return NotificationCenter
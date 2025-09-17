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
local Calendar = SafeRequire.require("custom.widgets.calendar")
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
    
    -- Создаем списки и календарь
    self.players_list = PlayersList.new()
    self.notification_list = NotificationList.new()
    self.calendar = Calendar.new()

    
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
    
    -- Контейнер для кнопки очистки
    self.clear_button_container = wibox.widget {
        clear_button.widget,
        forced_height = 35,  -- Всегда видима в блоке
        widget = wibox.container.constraint,
    }
    
    -- Контейнер для плееров и уведомлений
    local content_container = wibox.widget {
        -- Плееры (верх)
        self.players_list.widget,
        -- Уведомления (середина, растягивается)
        {
            self.notification_list.widget,
            top = 15,
            widget = wibox.container.margin,
        },
        nil,  -- Низ пустой
        forced_height = 440,
        layout = wibox.layout.align.vertical,
        widget = wibox.container.constraint,
    }
    
    -- Отдельный блок для кнопки (высота 100px)
    local button_block = wibox.widget {
        {
            self.clear_button_container,
            valign = "center",
            halign = "center",
            widget = wibox.container.place,
        },
        forced_height = 30,
        widget = wibox.container.constraint,
    }
    
    -- Левая колонка с кнопкой прибитой к низу
    self.left_column = wibox.widget {
        content_container,  -- Верх
        nil,                -- Пустое место
        button_block,       -- Низ (прибито к низу)
        layout = wibox.layout.align.vertical,
    }
    
    -- Основной контейнер с горизонтальным layout (правильный: align.horizontal)
    self.content_layout = wibox.widget {
        -- Левая колонка (фиксированная ширина)
        {
            self.left_column,
            forced_width = 350,
            widget = wibox.container.constraint,
        },
        -- Спейсинг 12px между колонками
        {
            forced_width = 12,
            widget = wibox.widget.base.empty_widget()
        },
        -- Правая ячейка: календарь, прижатый к правому краю.
        {
            {
                self.calendar.widget,
               
                widget = wibox.container.margin,
            },
            halign = "right",
            valign = "top",
            widget = wibox.container.place,
        },
        layout = wibox.layout.align.horizontal,
    }
    

    
    -- Контейнер с фиксированными размерами
    local container = wibox.widget {
        self.content_layout,
        forced_height = 480,
        widget = wibox.container.constraint
    }
    self.popup = Popup.new({
        content = container,
        forced_height = 480,
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
            self:_update_clear_button_visibility()
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
    
    -- Передаем ссылку на popup в списки
    self.players_list:set_popup(self.popup)
    self.notification_list:set_popup(self.popup)
    
    -- Подписываемся на изменения уведомлений
    NotificationManager:subscribe(function(notifications)
        self:_update_clear_button_visibility()
    end)
    

end

-- Переключение popup
function NotificationCenter:_toggle_popup()
    self.popup:toggle()
end

-- Обновление видимости кнопки очистки
function NotificationCenter:_update_clear_button_visibility()
    local notifications = NotificationManager:get_notifications()
    if #notifications > 0 then
        self.clear_button_container.visible = true
    else
        self.clear_button_container.visible = false
    end
end

return NotificationCenter
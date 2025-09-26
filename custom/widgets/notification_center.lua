-- ~/.config/awesome/custom/widgets/notification_center.lua
local gears = require("gears")
local wibox = require("wibox")
local awful = require("awful")
local NotificationCenter = {}
NotificationCenter.__index = NotificationCenter

-- Безопасное подключение зависимостей
local SafeRequire = require("custom.utils.safe_require")
local Button2 = SafeRequire.require("custom.widgets.button_2")
local Popup = SafeRequire.require("custom.widgets.popup")
local PlayersList = SafeRequire.require("custom.widgets.players_list")
local NotificationList = SafeRequire.require("custom.widgets.notification_list")
local Calendar = SafeRequire.require("custom.widgets.calendar")
local Clock = SafeRequire.require("custom.widgets.clock")
local Weather = SafeRequire.require("custom.widgets.weather")
local Switcher = SafeRequire.require("custom.widgets.switcher")
local NotificationManager = SafeRequire.require("custom.utils.notification_manager")
local GlobalStorage = SafeRequire.require("custom.utils.global_storage")
local CustomScroll = SafeRequire.require("custom.widgets.custom_scroll")
local settings = SafeRequire.require("custom.settings")
local Text = require("custom.widgets.base_widgets.text")


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

    -- Оборачиваем только виджет часов в Button2
    self.clock = Clock.new()
    local clock_button = Button2.new({
        content = self.clock.widget,
        width = 80,
        height = 24,
        on_click = function()
            self:_toggle_popup()
        end
    })
    
    -- Обновляем список плееров при наведении и проверяем смену дня
    clock_button.widget:connect_signal("mouse::enter", function()
        if self.players_list and self.players_list.refresh then
            self.players_list:refresh()
        end
        
        -- Проверяем смену дня и обновляем виджеты
        self:_check_and_update_day()
    end)
    self.widget = clock_button.widget
    
    -- Создаем списки, календарь и погоду
    local debug_logger = require("custom.utils.debug_logger")
    
    debug_logger.log("Пытаемся создать PlayersList...")
    local ok, result = pcall(function()
        return PlayersList.new()
    end)
    
    if not ok then
        debug_logger.log("Ошибка создания PlayersList: " .. tostring(result))
        self.players_list = nil
    else
        debug_logger.log("PlayersList создан успешно")
        self.players_list = result
        
        -- Проверяем методы
        debug_logger.log("PlayersList.widget: " .. tostring(self.players_list.widget ~= nil))
        debug_logger.log("PlayersList.set_popup: " .. tostring(type(self.players_list.set_popup)))
        debug_logger.log("PlayersList.refresh: " .. tostring(type(self.players_list.refresh)))
        
        -- Проверяем внутренние свойства
        if self.players_list.playerctl then
            debug_logger.log("PlayersList.playerctl: существует")
        else
            debug_logger.log("PlayersList.playerctl: ОТСУТСТВУЕТ!")
        end
    end
    
    self.notification_list = NotificationList.new()
    self.calendar = Calendar.new()
    self.weather = Weather.new()

    
    -- Кнопка очистки уведомлений
    local clear_button = Button2.new({
        content = Text.new({
            text = "Очистить все",
            theme_color = "text",
            font = settings.fonts.main .. " 10"
        }),
        height = 35,
        on_click = function()
            NotificationManager:clear_all()
        end
    })
    
    -- Оборачиваем кнопку в контейнер с флагом visible
    self.clear_button_wrapper = wibox.widget {
        clear_button.widget,
        visible = false,
        widget = wibox.container.background
    }
    
    -- Переключатель уведомлений с Text
    local Text = require("custom.widgets.base_widgets.text")
    self.notifications_switcher = Switcher.new({
        label_widget = Text.new({
            text = "Не беспокоить",
            theme_color = "text",
            font = settings.fonts.main .. " Bold 10"
        }),
        initial_state = false,
        on_change = function(state)
            GlobalStorage.set("notifications_disabled", state)
            if state then
                NotificationManager:enable_silent_mode()
            else
                NotificationManager:disable_silent_mode()
            end
        end
    })
    
    -- Контейнер для кнопки и переключателя по разным краям
    self.clear_button = clear_button
    self.controls_container = wibox.widget {
        {
            self.notifications_switcher.widget,
            valign = "center",
            widget = wibox.container.place
        },
        nil,
        {
            self.clear_button_wrapper,
            valign = "center",
            widget = wibox.container.place
        },
        layout = wibox.layout.align.horizontal
    }
    
    self.clear_button_container = wibox.widget {
        self.controls_container,
        forced_height = 35,
        forced_width = 350,
        widget = wibox.container.constraint
    }
    
    -- Контент для скролла
    local scroll_content = wibox.widget {
        self.players_list.widget,
        {
            self.notification_list.widget,
            top = settings.widgets.list_item.gap_between_lists,
            widget = wibox.container.margin,
        },
        layout = wibox.layout.fixed.vertical,
    }
    
    -- Расчет высоты scroll: 6 уведомлений + гепы
    local viewport_height = 6 * settings.widgets.list_item.height + 5 * settings.widgets.list_item.spacing + 10
    
    -- Скролл контейнер
    self.scroll = CustomScroll.new({
        width = 350,
        height = viewport_height,
        inner_height = 800,
        step = 50
    })
    
    self.scroll:set_content(scroll_content)
    
    local content_container = self.scroll:get_widget()
    
    -- Отдельный блок для кнопки и переключателя
    local button_block = self.clear_button_container
    
    -- Левая колонка с кнопкой
    self.left_column = wibox.widget {
        content_container,  -- Скролл контейнер
        button_block,       -- Кнопка
        spacing = settings.widgets.list_item.spacing,
        layout = wibox.layout.fixed.vertical,
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
        -- Правая ячейка: календарь и погода
        {
            self.calendar.widget,
            {
                self.weather.widget,
                top = 12,
                widget = wibox.container.margin,
            },
            spacing = 0,
            layout = wibox.layout.fixed.vertical,
        },
        layout = wibox.layout.align.horizontal,
    }
    

    
    -- Контейнер с фиксированными размерами
    local container = wibox.widget {
        self.content_layout,
      
        widget = wibox.container.constraint
    }
    self.popup = Popup.new({
        content = container,
        forced_height = 500,
        preferred_positions = "bottom",
        preferred_anchors = "middle",
        offset = { y = 5 }
    })
    
    -- Проверяем что popup загрузился правильно
    if self.popup and self.popup.on and type(self.popup.on) == "function" then
        -- Включаем события для отслеживания состояния
        self.popup:on("opened", function()
            local DebugLogger = require("custom.utils.debug_logger")
            DebugLogger.log("NOTIFICATION_CENTER: popup opened, setting notification_center_open to true")
            
            if self.scroll and self.scroll.set_visible then
                self.scroll:set_visible(true)
            end
            
            if self.calendar and self.calendar.update then
                self.calendar:update()
            end
            
            if self.notification_list and self.notification_list.update_times then
                self.notification_list:update_times()
            end
            
            if GlobalStorage and GlobalStorage.set then
                GlobalStorage.set("notification_center_open", true)
            end
            
            self.widget:emit_signal("widget::redraw_needed")
        end)
        
        self.popup:on("closed", function()
            local DebugLogger = require("custom.utils.debug_logger")
            DebugLogger.log("NOTIFICATION_CENTER: popup closed, setting notification_center_open to false")
            
            if self.scroll then
                if self.scroll.reset then
                    self.scroll:reset()
                end
                if self.scroll.set_visible then
                    self.scroll:set_visible(false)
                end
            end
            if GlobalStorage and GlobalStorage.set then
                GlobalStorage.set("notification_center_open", false)
            end
        end)
    end
    
    -- Передаем ссылку на popup в списки (с проверкой)
    if self.players_list and self.players_list.set_popup then
        self.players_list:set_popup(self.popup)
    end
    if self.notification_list and self.notification_list.set_popup then
        self.notification_list:set_popup(self.popup)
    end
    if self.notification_list and self.notification_list.set_notification_center then
        self.notification_list:set_notification_center(self)
    end
    
    -- Подписываемся на изменения уведомлений
    NotificationManager:subscribe(function(notifications)
        self:_update_clear_button_visibility()
    end)
    


end

-- Переключение popup
function NotificationCenter:_toggle_popup()
    if self.popup:get_visible() then
        self.popup:hide()
        GlobalStorage.set("popup_open", false)
    else
        self.popup:show()
        GlobalStorage.set("popup_open", true)
    end
end

-- Обновление высоты scroll на основе количества элементов
function NotificationCenter:_update_scroll_height()
    local notifications = NotificationManager:get_notifications()
    local players_count = 0
    
    -- Получаем количество плееров из players_list
    if self.players_list and self.players_list.players_widgets then
        for _ in pairs(self.players_list.players_widgets) do
            players_count = players_count + 1
        end
    end
    
    local notifications_count = #notifications
    
    -- Расчет высоты: элементы + гепы между ними + геп между списками
    local players_height = players_count * settings.widgets.list_item.height + 
                          math.max(0, players_count - 1) * settings.widgets.list_item.spacing
    
    local notifications_height = notifications_count * settings.widgets.list_item.height + 
                                math.max(0, notifications_count - 1) * settings.widgets.list_item.spacing
    
    local gap_between = (players_count > 0 and notifications_count > 0) and settings.widgets.list_item.gap_between_lists or 0
    
    local total_height = players_height + notifications_height + gap_between
    
    -- Передаем размеры в notification_list для правильного позиционирования плашки
    if self.notification_list and self.notification_list.set_dimensions and self.scroll then
        self.notification_list:set_dimensions(players_height + gap_between, self.scroll.viewport_height)
    end
    
    -- Минимальная высота - высота viewport
    if self.scroll then
        local new_height = math.max(total_height, self.scroll.viewport_height)
        if self.scroll.update_inner_height then
            self.scroll:update_inner_height(new_height)
        else
            self.scroll.inner_height = new_height
        end
    end
end

-- Обновление видимости кнопки очистки
function NotificationCenter:_update_clear_button_visibility()
    local notifications = NotificationManager:get_notifications()
    -- Кнопка очистки появляется при 1+ уведомлениях
    if #notifications >= 1 then
        self.clear_button_wrapper.visible = true
    else
        self.clear_button_wrapper.visible = false
    end
    -- Принудительно обновляем layout
    self.controls_container:emit_signal("widget::layout_changed")
end

-- Проверка смены дня и обновление виджетов
function NotificationCenter:_check_and_update_day()
    local current_date = os.date("%Y-%m-%d")
    
    if not self.last_date or self.last_date ~= current_date then
        self.last_date = current_date
        
        -- Обновляем календарь
        if self.calendar and self.calendar.update then
            self.calendar:update()
        end
        
        -- Обновляем погоду
        if self.weather and self.weather.update then
            self.weather:update()
        end
    end
end

return NotificationCenter
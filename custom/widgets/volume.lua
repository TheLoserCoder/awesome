-- ~/.config/awesome/custom/widgets/volume.lua
local gears = require("gears")
local wibox = require("wibox")
local awful = require("awful")

local Volume = {}
Volume.__index = Volume

-- Получаем зависимости
local Provider = require("custom.widgets.provider")
local Slider = require("custom.widgets.slider")
local Button = require("custom.widgets.button")

-- Функция для выполнения команд
local function run_cmd(cmd)
    local f = io.popen(cmd .. " 2>/dev/null")
    if not f then return nil end
    local out = f:read("*all")
    f:close()
    return out
end

-- Получение громкости
local function get_volume()
    local out = run_cmd("amixer get Master")
    if out then
        local v = out:match("(%d?%d?%d)%%")
        if v then return tonumber(v) end
    end
    return 0
end

-- Проверка на mute
local function is_muted()
    local out = run_cmd("amixer get Master")
    if out and out:match("%[off%]") then return true end
    return false
end

-- Создание нового виджета громкости
function Volume.new(config)
    config = config or {}
    local self = setmetatable({}, Volume)
    
    -- Настройки
    self.show_icon = config.show_icon ~= false -- по умолчанию показываем
    self.width = config.width or 120
    self.update_interval = config.update_interval or 1.0
    self.debounce_timeout = config.debounce_timeout or 0.15
    
    -- Создаем компоненты
    self:_create_widgets()
    self:_setup_volume_control()
    self:_setup_sync_timer()
    
    return self
end

-- Создание виджетов
function Volume:_create_widgets()
    -- Получаем цвета
    local colors = Provider.get_colors()
    
    -- Создаем кнопку mute
    local mute_icon = wibox.widget {
        text = "",
        align = "center",
        valign = "center",
        widget = wibox.widget.textbox
    }
    
    self.mute_button = Button.new({
        content = mute_icon,
        width = 24,
        height = 24,
        on_click = function()
            awful.spawn("amixer set Master toggle", false)
            -- Немедленно обновляем иконку через небольшую задержку
            gears.timer.start_new(0.1, function()
                self:_update_icon()
                return false
            end)
        end
    })
    
    -- Создаем slider
    self.slider = Slider.new({
        minimum = 0,
        maximum = 100,
        value = get_volume(),
        width = self.width,
        bg_color = colors.surface,
        bar_active_color = colors.accent,
        handle_color = colors.accent
    })
    
    -- Сохраняем ссылку на иконку для обновления
    self.mute_icon = mute_icon
    

    
    -- Создаем основной виджет
    if self.show_icon then
        self.widget = wibox.widget {
            self.mute_button.widget,
            self.slider.widget,
            spacing = 8,
            layout = wibox.layout.fixed.horizontal
        }
    else
        self.widget = self.slider.widget
    end
end

-- Настройка управления громкостью
function Volume:_setup_volume_control()
    -- Флаги для контроля обновлений
    self.programmatic_update = false
    self.user_interacting = false -- Пользователь взаимодействует со slider
    
    -- Debounce таймер
    self.pending_volume = nil
    self.set_volume_timer = gears.timer {
        timeout = self.debounce_timeout,
        autostart = false,
        single_shot = true,
        callback = function()
            if self.pending_volume ~= nil then
                awful.spawn("amixer set Master " .. self.pending_volume .. "%", false)
                self.pending_volume = nil
            end
            -- После установки громкости снимаем блокировку
            gears.timer.start_new(0.2, function()
                self.user_interacting = false
                return false
            end)
        end
    }
    
    -- Обработка изменения значения slider
    self.slider:connect_signal("property::value", function()
        if self.programmatic_update then
            self.programmatic_update = false
            return
        end
        
        -- Пользователь начал взаимодействие
        self.user_interacting = true
        
        local value = self.slider:get_value()
        local val = math.floor(value + 0.5)
        if val < 0 then val = 0 end
        if val > 150 then val = 150 end
        self.pending_volume = val
        
        if self.set_volume_timer.started then
            self.set_volume_timer:stop()
        end
        self.set_volume_timer:start()
    end)
end

-- Настройка таймера синхронизации
function Volume:_setup_sync_timer()
    gears.timer {
        timeout = self.update_interval,
        autostart = true,
        callback = function()
            local vol = get_volume() or 0
            
            -- Обновляем slider только если пользователь не взаимодействует
            if not self.user_interacting then
                local current_vol = self.slider:get_value()
                if current_vol ~= vol then
                    self.programmatic_update = true
                    self.slider:set_value(vol)
                end
            end
            
            -- Обновляем иконку
            self:_update_icon()
        end
    }
end

-- Получение текущего значения
function Volume:get_value()
    return self.slider:get_value()
end

-- Установка значения
function Volume:set_value(value)
    self.slider:set_value(value)
end

-- Показать/скрыть иконку
function Volume:set_show_icon(show)
    self.show_icon = show
    -- Пересоздаем виджет
    self:_create_widgets()
end

-- Подключение сигналов
function Volume:connect_signal(signal, callback)
    if signal == "property::value" then
        self.slider:connect_signal(signal, callback)
    else
        self.widget:connect_signal(signal, callback)
    end
end

-- Отключение сигналов
function Volume:disconnect_signal(signal, callback)
    if signal == "property::value" then
        self.slider:disconnect_signal(signal, callback)
    else
        self.widget:disconnect_signal(signal, callback)
    end
end

-- Обновление иконки
function Volume:_update_icon()
    if self.show_icon then
        if is_muted() then
            self.mute_icon.text = ""
        else
            self.mute_icon.text = ""
        end
    end
end

return Volume
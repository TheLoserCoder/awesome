-- ~/.config/awesome/custom/widgets/volume.lua
local gears = require("gears")
local wibox = require("wibox")
local awful = require("awful")

local Volume = {}
Volume.__index = Volume

-- Получаем зависимости
local Provider = require("custom.widgets.provider")
local Slider = require("custom.widgets.slider")

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
    local out = run_cmd("pactl get-sink-volume @DEFAULT_SINK@")
    if out then
        local v = out:match("(%d?%d?%d)%%")
        if v then return tonumber(v) end
    end

    local out2 = run_cmd("amixer get Master")
    if out2 then
        local v2 = out2:match("(%d?%d?%d)%%")
        if v2 then return tonumber(v2) end
    end

    return 0
end

-- Проверка на mute
local function is_muted()
    local out = run_cmd("pactl get-sink-mute @DEFAULT_SINK@")
    if out and out:match("yes") then return true end

    local out2 = run_cmd("amixer get Master")
    if out2 and out2:match("%[off%]") then return true end

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
    -- Иконка громкости
    self.icon = wibox.widget {
        text = "🔊",
        align = "center",
        valign = "center",
        widget = wibox.widget.textbox
    }
    
    -- Получаем цвета
    local colors = Provider.get_colors()
    
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
    
    -- Настраиваем события иконки
    self.icon:buttons(gears.table.join(
        awful.button({}, 1, function()
            awful.spawn("pactl set-sink-mute @DEFAULT_SINK@ toggle", false)
        end),
        awful.button({}, 3, function()
            awful.spawn("pactl set-sink-volume @DEFAULT_SINK@ 50%", false)
        end)
    ))
    
    -- Создаем основной виджет
    if self.show_icon then
        self.widget = wibox.widget {
            self.icon,
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
    -- Флаг для предотвращения рекурсии
    self.programmatic_update = false
    
    -- Debounce таймер
    self.pending_volume = nil
    self.set_volume_timer = gears.timer {
        timeout = self.debounce_timeout,
        autostart = false,
        single_shot = true,
        callback = function()
            if self.pending_volume ~= nil then
                awful.spawn("pactl set-sink-volume @DEFAULT_SINK@ " .. self.pending_volume .. "%", false)
                self.pending_volume = nil
            end
        end
    }
    
    -- Обработка изменения значения slider
    self.slider:connect_signal("property::value", function()
        if self.programmatic_update then
            self.programmatic_update = false
            return
        end
        
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
            
            -- Обновляем slider
            local current_vol = self.slider:get_value()
            if current_vol ~= vol then
                self.programmatic_update = true
                self.slider:set_value(vol)
            end
            
            -- Обновляем иконку
            if self.show_icon then
                if is_muted() then
                    self.icon.text = "🔇"
                else
                    if vol == 0 then
                        self.icon.text = "🔈"
                    elseif vol < 60 then
                        self.icon.text = "🔉"
                    else
                        self.icon.text = "🔊"
                    end
                end
            end
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

return Volume
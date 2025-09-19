-- ~/.config/awesome/custom/widgets/weather.lua
local wibox = require("wibox")
local gears = require("gears")
local awful = require("awful")
local Provider = require("custom.widgets.provider")
local settings = require("custom.settings")
local GlobalStorage = require("custom.utils.global_storage")
local DebugLogger = require("custom.utils.debug_logger")

local Weather = {}
Weather.__index = Weather

function Weather.new()
    local self = setmetatable({}, Weather)
    
    DebugLogger.log("[WEATHER] Creating weather widget")
    
    local colors = Provider.get_colors()
    
    -- Виджеты для первой строки
    self.location_widget = wibox.widget {
        markup = '<span color="' .. colors.text_muted .. '">Кривой Рог</span>',
        font = settings.fonts.main .. " Bold 14",
        widget = wibox.widget.textbox,
    }
    
    self.current_icon = wibox.widget {
        text = "🌤️",
        font = settings.fonts.main .. " 18",
        widget = wibox.widget.textbox,
    }
    
    self.current_temp = wibox.widget {
        markup = '<span color="' .. colors.text .. '">--°C</span>',
        font = settings.fonts.main .. " Bold 18",
        widget = wibox.widget.textbox,
    }
    
    -- Временные промежутки (6 штук)
    self.forecast_widgets = {}
    for i = 1, 6 do
        self.forecast_widgets[i] = {
            icon = wibox.widget {
                text = "🌤️",
                font = settings.fonts.main .. " 12",
                align = "center",
                widget = wibox.widget.textbox,
            },
            temp = wibox.widget {
                markup = '<span color="' .. colors.text .. '">--°</span>',
                font = settings.fonts.main .. " 9",
                align = "center",
                widget = wibox.widget.textbox,
            },
            time = wibox.widget {
                markup = '<span color="' .. colors.text_muted .. '">--:--</span>',
                font = settings.fonts.main .. " 8",
                align = "center",
                widget = wibox.widget.textbox,
            }
        }
    end
    
    -- Параметры внизу
    self.humidity_widget = wibox.widget {
        markup = '<span color="' .. colors.text_secondary .. '">' .. settings.icons.weather.humidity .. ' --%</span>',
        font = settings.fonts.main .. " 9",
        widget = wibox.widget.textbox,
    }
    
    self.wind_widget = wibox.widget {
        markup = '<span color="' .. colors.text_secondary .. '">' .. settings.icons.weather.wind_speed .. ' -- м/с</span>',
        font = settings.fonts.main .. " 9",
        widget = wibox.widget.textbox,
    }
    
    self.pressure_widget = wibox.widget {
        markup = '<span color="' .. colors.text_secondary .. '">' .. settings.icons.weather.pressure .. ' -- гПа</span>',
        font = settings.fonts.main .. " 9",
        widget = wibox.widget.textbox,
    }
    
    -- Создаем layout для временных промежутков
    local forecast_layout = wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        spacing = 8
    }
    
    for i = 1, 6 do
        local forecast_item = wibox.widget {
            {
                self.forecast_widgets[i].icon,
                self.forecast_widgets[i].temp,
                self.forecast_widgets[i].time,
                spacing = 2,
                layout = wibox.layout.fixed.vertical,
            },
            forced_width = 30,
            widget = wibox.container.constraint,
        }
        forecast_layout:add(forecast_item)
    end
    
    -- Основной виджет
    self.widget = wibox.widget {
        {
            {
                {
                    -- Первая строка: город слева, иконка+температура справа
                    {
                        self.location_widget,
                        nil,
                        {
                            self.current_icon,
                            self.current_temp,
                            spacing = 6,
                            layout = wibox.layout.fixed.horizontal,
                        },
                        layout = wibox.layout.align.horizontal,
                    },
                    -- Вторая строка: прогноз на 6 временных промежутков
                    {
                        forecast_layout,
                        top = 8,
                        widget = wibox.container.margin,
                    },
                    -- Третья строка: параметры по центру
                    {
                        {
                            {
                                self.humidity_widget,
                                self.wind_widget,
                                self.pressure_widget,
                                spacing = 12,
                                layout = wibox.layout.fixed.horizontal,
                            },
                            halign = "center",
                            widget = wibox.container.place,
                        },
                        top = 8,
                        widget = wibox.container.margin,
                    },
                    layout = wibox.layout.fixed.vertical,
                },
                margins = 12,
                widget = wibox.container.margin,
            },
            valign = "center",
            widget = wibox.container.place,
        },
        bg = colors.surface,
        shape = gears.shape.rounded_rect,
        forced_width = 250,
        forced_height = 140,
        widget = wibox.container.background,
        buttons = awful.util.table.join(
            awful.button({}, 1, function()
                awful.spawn(settings.commands.weather_app)
            end)
        )
    }
    
    -- Слушаем обновления погоды
    GlobalStorage.listen("weather_data", function(data)
        self:update_weather(data)
    end)
    
    -- Проверяем есть ли уже данные
    local existing_data = GlobalStorage.get("weather_data")
    DebugLogger.log("[WEATHER] Existing data: " .. (existing_data and "found" or "not found"))
    
    if existing_data then
        DebugLogger.log("[WEATHER] Using existing data")
        self:update_weather(existing_data)
    else
        -- Запускаем API если данных нет
        DebugLogger.log("[WEATHER] Starting API fetch")
        local WeatherAPI = require("custom.utils.weather_api")
        WeatherAPI.fetch_weather()
    end
    
    return self
end

function Weather:update_weather(data)
    if not data then
        self:show_no_data()
        return
    end
    
    -- Обновляем текущую температуру и иконку
    if data.temperature then
        local colors = Provider.get_colors()
        self.current_temp.markup = '<span color="' .. colors.text .. '">' .. string.format("%.0f°C", data.temperature) .. '</span>'
    end
    
    if data.weather_code then
        local icon = self:get_weather_icon(data.weather_code)
        self.current_icon.text = icon
    end
    
    -- Обновляем прогноз (пока используем текущие данные для всех промежутков)
    if data.forecast then
        for i = 1, math.min(6, #data.forecast) do
            local forecast_item = data.forecast[i]
            if forecast_item then
                self.forecast_widgets[i].time.text = forecast_item.time or "--:--"
                local hour = tonumber(forecast_item.time:match("(%d+):")) or 0
                self.forecast_widgets[i].icon.text = self:get_weather_icon(forecast_item.weather_code or "clearsky", hour)
                local colors = Provider.get_colors()
                self.forecast_widgets[i].temp.markup = '<span color="' .. colors.text .. '">' .. (forecast_item.temperature and string.format("%.0f°", forecast_item.temperature) or "--°") .. '</span>'
            end
        end
    else
        -- Заполняем тестовыми данными если нет прогноза
        for i = 1, 6 do
            local hour = (i - 1) * 4
            self.forecast_widgets[i].time.text = string.format("%02d:00", hour)
            self.forecast_widgets[i].icon.text = self:get_weather_icon(data.weather_code or "clearsky", hour)
            local colors = Provider.get_colors()
            self.forecast_widgets[i].temp.markup = '<span color="' .. colors.text .. '">' .. (data.temperature and string.format("%.0f°", data.temperature + math.random(-3, 3)) or "--°") .. '</span>'
        end
    end
    
    -- Обновляем параметры внизу
    local colors = Provider.get_colors()
    if data.humidity then
        self.humidity_widget.markup = '<span color="' .. colors.text_secondary .. '">' .. settings.icons.weather.humidity .. ' ' .. string.format("%.0f%%", data.humidity) .. '</span>'
    end
    
    if data.wind_speed then
        self.wind_widget.markup = '<span color="' .. colors.text_secondary .. '">' .. settings.icons.weather.wind_speed .. ' ' .. string.format("%.0f м/с", data.wind_speed) .. '</span>'
    end
    
    if data.pressure then
        self.pressure_widget.markup = '<span color="' .. colors.text_secondary .. '">' .. settings.icons.weather.pressure .. ' ' .. string.format("%.0f гПа", data.pressure) .. '</span>'
    end
end

function Weather:show_no_data()
    local colors = Provider.get_colors()
    self.current_temp.markup = '<span color="' .. colors.text .. '">Нет данных</span>'
    self.current_icon.text = "❓"
    
    for i = 1, 6 do
        self.forecast_widgets[i].time.markup = '<span color="' .. colors.text_muted .. '">--:--</span>'
        self.forecast_widgets[i].icon.text = "❓"
        self.forecast_widgets[i].temp.markup = '<span color="' .. colors.text .. '">--°</span>'
    end
    
    self.humidity_widget.markup = '<span color="' .. colors.text_secondary .. '">' .. settings.icons.weather.humidity .. ' --</span>'
    self.wind_widget.markup = '<span color="' .. colors.text_secondary .. '">' .. settings.icons.weather.wind_speed .. ' --</span>'
    self.pressure_widget.markup = '<span color="' .. colors.text_secondary .. '">' .. settings.icons.weather.pressure .. ' --</span>'
end

function Weather:get_weather_icon(weather_code, hour)
    local icons = settings.icons.weather
    
    DebugLogger.log("[WEATHER] Weather code: " .. (weather_code or "nil") .. ", hour: " .. (hour or "current"))
    
    -- Определяем день/ночь по времени
    local is_night = false
    if hour then
        is_night = hour < 6 or hour >= 20  -- Ночь: 20:00-05:59
    else
        local current_hour = tonumber(os.date("%H"))
        is_night = current_hour < 6 or current_hour >= 20
    end
    
    -- Сопоставление кодов met.no API с иконками
    if not weather_code then
        return icons.default
    end
    
    -- Убираем суффиксы _day/_night для обработки
    local base_code = weather_code:gsub("_day$", ""):gsub("_night$", "")
    
    -- Основные коды
    if base_code == "partlycloudy" or base_code == "fair" then
        return is_night and icons.partly_cloudy_night or icons.partly_cloudy_day
    elseif base_code == "clearsky" then
        return is_night and icons.clear_night or icons.clear_day
    elseif base_code == "cloudy" then
        return icons.cloudy
    elseif base_code:match("rain") or base_code:match("lightrain") or base_code:match("heavyrain") then
        return icons.rain
    elseif base_code:match("snow") or base_code:match("lightsnow") or base_code:match("heavysnow") then
        return icons.snow
    elseif base_code == "fog" then
        return icons.fog
    elseif base_code == "sleet" then
        return icons.rain
    else
        DebugLogger.log("[WEATHER] Unknown weather code: " .. weather_code)
        return icons.default
    end
end

return Weather
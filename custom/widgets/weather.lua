-- ~/.config/awesome/custom/widgets/weather.lua
local wibox = require("wibox")
local gears = require("gears")
local awful = require("awful")

local settings = require("custom.settings")
local GlobalStorage = require("custom.utils.global_storage")


local Weather = {}
Weather.__index = Weather

function Weather.new()
    local self = setmetatable({}, Weather)
    

    
    local colors = settings.colors
    
    -- Виджеты для первой строки
    local Text = require("custom.widgets.base_widgets.text")
    
    self.location_widget = Text.new({
        text = "Кривой Рог",
        theme_color = "text_muted",
        font = settings.fonts.main .. " Bold 14"
    })
    
    self.current_icon = Text.new({
        text = "🌤️",
        theme_color = "text",
        font = settings.fonts.main .. " 18"
    })
    
    self.current_temp = Text.new({
        text = "--°C",
        theme_color = "text",
        font = settings.fonts.main .. " Bold 18"
    })
    
    -- Временные промежутки (6 штук)
    self.forecast_widgets = {}
    for i = 1, 6 do
        self.forecast_widgets[i] = {
            icon = Text.new({
                text = "🌤️",
                theme_color = "text_muted",
                font = settings.fonts.main .. " 12"
            }),
            temp = Text.new({
                text = "--°",
                theme_color = "text",
                font = settings.fonts.main .. " 9"
            }),
            time = Text.new({
                text = "--:--",
                theme_color = "text_muted",
                font = settings.fonts.main .. " 8"
            })
        }
    end
    
    -- Параметры внизу
    self.humidity_widget = Text.new({
        text = settings.icons.weather.humidity .. " --%",
        theme_color = "text_secondary",
        font = settings.fonts.main .. " 9"
    })
    
    self.wind_widget = Text.new({
        text = settings.icons.weather.wind_speed .. " -- м/с",
        theme_color = "text_secondary",
        font = settings.fonts.main .. " 9"
    })
    
    self.pressure_widget = Text.new({
        text = settings.icons.weather.pressure .. " -- гПа",
        theme_color = "text_secondary",
        font = settings.fonts.main .. " 9"
    })
    
    -- Создаем layout для временных промежутков
    local forecast_layout = wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        spacing = 8
    }
    
    for i = 1, 6 do
        local forecast_item = wibox.widget {
            {
                {
                    self.forecast_widgets[i].icon,
                    halign = "center",
                    widget = wibox.container.place
                },
                {
                    self.forecast_widgets[i].temp,
                    halign = "center",
                    widget = wibox.container.place
                },
                {
                    self.forecast_widgets[i].time,
                    halign = "center",
                    widget = wibox.container.place
                },
                spacing = 2,
                layout = wibox.layout.fixed.vertical,
            },
            forced_width = 30,
            widget = wibox.container.constraint,
        }
        forecast_layout:add(forecast_item)
    end
    
    -- Основной виджет
    local Container = require("custom.widgets.base_widgets.container")
    local content = wibox.widget {
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
                    {
                        self.humidity_widget,
                        valign = "center",
                        widget = wibox.container.place
                    },
                    {
                        self.wind_widget,
                        valign = "center",
                        widget = wibox.container.place
                    },
                    {
                        self.pressure_widget,
                        valign = "center",
                        widget = wibox.container.place
                    },
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
    }
    
    self.widget = Container.new({
        theme_color = "surface",
        content = content,
        margins = 12,
        width = 250,
        height = 140,
        valign = "center",
        shape = function(cr, w, h) gears.shape.rounded_rect(cr, w, h, settings.dimensions.corner_radius) end
    })
    
    self.widget:connect_signal("button::press", function(_, _, _, button)
        if button == 1 then
            awful.spawn(settings.commands.weather_app)
        end
    end)
    
    -- Слушаем обновления погоды
    GlobalStorage.listen("weather_data", function(data)
        self:update_weather(data)
    end)
    
    -- Проверяем есть ли уже данные
    local existing_data = GlobalStorage.get("weather_data")
    
    if existing_data then
        self:update_weather(existing_data)
    else
        -- Запускаем API если данных нет
        local WeatherAPI = require("custom.utils.weather_api")
        WeatherAPI.fetch_weather()
        
        -- Принудительно обновляем через некоторое время
        gears.timer.start_new(2, function()
            local data = GlobalStorage.get("weather_data")
            if data then
                self:update_weather(data)
            end
            return false
        end)
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
        self.current_temp:update_text(string.format("%.0f°C", data.temperature))
    end
    
    if data.weather_code then
        local icon = self:get_weather_icon(data.weather_code)
        self.current_icon:update_text(icon)
    end
    
    -- Обновляем прогноз (пока используем текущие данные для всех промежутков)
    if data.forecast then
        for i = 1, math.min(6, #data.forecast) do
            local forecast_item = data.forecast[i]
            if forecast_item then
                self.forecast_widgets[i].time:update_text(forecast_item.time or "--:--")
                local hour = tonumber(forecast_item.time:match("(%d+):")) or 0
                local icon = self:get_weather_icon(forecast_item.weather_code or "clearsky", hour)
                self.forecast_widgets[i].icon:update_text(icon)
                self.forecast_widgets[i].temp:update_text(forecast_item.temperature and string.format("%.0f°", forecast_item.temperature) or "--°")
            end
        end
    else
        -- Заполняем тестовыми данными если нет прогноза
        for i = 1, 6 do
            local hour = (i - 1) * 4
            self.forecast_widgets[i].time:update_text(string.format("%02d:00", hour))
            local icon = self:get_weather_icon(data.weather_code or "clearsky", hour)
            self.forecast_widgets[i].icon:update_text(icon)
            self.forecast_widgets[i].temp:update_text(data.temperature and string.format("%.0f°", data.temperature + math.random(-3, 3)) or "--°")
        end
    end
    
    -- Обновляем параметры внизу
    if data.humidity then
        self.humidity_widget:update_text(settings.icons.weather.humidity .. ' ' .. string.format("%.0f%%", data.humidity))
    end
    
    if data.wind_speed then
        self.wind_widget:update_text(settings.icons.weather.wind_speed .. ' ' .. string.format("%.0f м/с", data.wind_speed))
    end
    
    if data.pressure then
        self.pressure_widget:update_text(settings.icons.weather.pressure .. ' ' .. string.format("%.0f гПа", data.pressure))
    end
end

function Weather:show_no_data()
    self.current_temp:update_text("Нет данных")
    self.current_icon:update_text("❓")
    
    for i = 1, 6 do
        self.forecast_widgets[i].time:update_text("--:--")
        self.forecast_widgets[i].icon:update_text("❓")
        self.forecast_widgets[i].temp:update_text("--°")
    end
    
    self.humidity_widget:update_text(settings.icons.weather.humidity .. ' --')
    self.wind_widget:update_text(settings.icons.weather.wind_speed .. ' --')
    self.pressure_widget:update_text(settings.icons.weather.pressure .. ' --')
end

function Weather:get_weather_icon(weather_code, hour)
    local icons = settings.icons.weather
    

    
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

        return icons.default
    end
end

return Weather
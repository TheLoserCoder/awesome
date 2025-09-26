-- ~/.config/awesome/custom/utils/weather_api.lua
local awful = require("awful")
local gears = require("gears")
local json = require("dkjson")
local settings = require("custom.settings")
local GlobalStorage = require("custom.utils.global_storage")


local WeatherAPI = {}

function WeatherAPI.setup()
    -- Запускаем первый запрос сразу
    WeatherAPI.fetch_weather()
    
    -- Настраиваем таймер для регулярных обновлений
    gears.timer {
        timeout = settings.api.weather.update_interval,
        autostart = true,
        callback = function()
            WeatherAPI.fetch_weather()
        end
    }
end

function WeatherAPI.fetch_weather()
    local lat = settings.api.weather.latitude
    local lon = settings.api.weather.longitude
    local user_agent = settings.api.weather.user_agent
    

    
    awful.spawn.easy_async_with_shell(
        string.format('timeout 10 curl -s -H "User-Agent: %s" "https://api.met.no/weatherapi/locationforecast/2.0/compact?lat=%s&lon=%s"', 
            user_agent, lat, lon),
        function(stdout, stderr, exitreason, exitcode)

            
            if exitcode ~= 0 then

                -- Устанавливаем тестовые данные при ошибке
                local test_data = {
                    temperature = 15,
                    humidity = 65,
                    wind_speed = 2,
                    pressure = 1013,
                    weather_code = "clearsky_day"
                }
                GlobalStorage.set("weather_data", test_data)
                return
            end
            
            -- Проверяем на ошибку API
            if stdout:match("400 Bad Request") or stdout:match("did not pass regex check") then

                GlobalStorage.set("weather_data", nil)
                return
            end
            
            local data, pos, err = json.decode(stdout)
            if not data then

                GlobalStorage.set("weather_data", nil)
                return
            end
            
            -- Парсим данные
            local weather_data = WeatherAPI.parse_weather_data(data)
            if weather_data then

                GlobalStorage.set("weather_data", weather_data)
            else

                GlobalStorage.set("weather_data", nil)
            end
        end
    )
end

function WeatherAPI.parse_weather_data(data)

    
    if not data.properties then

        return nil
    end
    
    if not data.properties.timeseries then

        return nil
    end
    
    if #data.properties.timeseries == 0 then

        return nil
    end
    
    local current = data.properties.timeseries[1]

    
    if not current.data then

        return nil
    end
    
    if not current.data.instant then

        return nil
    end
    
    if not current.data.instant.details then

        return nil
    end
    
    local details = current.data.instant.details
    local weather_data = {}
    
    -- Температура
    weather_data.temperature = details.air_temperature
    
    -- Влажность
    weather_data.humidity = details.relative_humidity
    
    -- Скорость ветра
    weather_data.wind_speed = details.wind_speed
    
    -- Давление
    weather_data.pressure = details.air_pressure_at_sea_level
    
    -- Код погоды (упрощенный)
    if current.data.next_1_hours and current.data.next_1_hours.summary then
        weather_data.weather_code = current.data.next_1_hours.summary.symbol_code
    elseif current.data.next_6_hours and current.data.next_6_hours.summary then
        weather_data.weather_code = current.data.next_6_hours.summary.symbol_code
    else
        weather_data.weather_code = "clearsky_day"
    end
    
    -- Парсим прогноз: 6 интервалов по 4 часа начиная с 00:00
    weather_data.forecast = {}
    
    for i = 1, 6 do
        local target_hour = (i - 1) * 4
        
        -- Ищем соответствующие данные в timeseries
        for j = 1, #data.properties.timeseries do
            local forecast_item = data.properties.timeseries[j]
            if forecast_item and forecast_item.data and forecast_item.data.instant then
                local forecast_time = forecast_item.time
                local hour = tonumber(forecast_time:match("T(%d%d):")) or 0
                
                if hour == target_hour then
                    local forecast_details = forecast_item.data.instant.details
                    
                    -- Определяем код погоды
                    local forecast_weather_code = "clearsky_day"
                    if forecast_item.data.next_1_hours and forecast_item.data.next_1_hours.summary then
                        forecast_weather_code = forecast_item.data.next_1_hours.summary.symbol_code
                    elseif forecast_item.data.next_6_hours and forecast_item.data.next_6_hours.summary then
                        forecast_weather_code = forecast_item.data.next_6_hours.summary.symbol_code
                    end
                    
                    weather_data.forecast[i] = {
                        time = string.format("%02d:00", target_hour),
                        temperature = forecast_details.air_temperature,
                        weather_code = forecast_weather_code
                    }
                    break
                end
            end
        end
    end
    
    return weather_data
end

return WeatherAPI
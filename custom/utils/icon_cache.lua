-- ~/.config/awesome/custom/utils/icon_cache.lua
local gears = require("gears")

local IconCache = {}

-- Кэш для сохранения путей к иконкам
IconCache.cache = {}
IconCache.cache_dir = "/tmp/awesome_icons/"

function IconCache.init()
    -- Создаем директорию для кэша
    os.execute("mkdir -p " .. IconCache.cache_dir)
end

function IconCache.save_userdata_icon(userdata_icon, app_name)
    if not userdata_icon or type(userdata_icon) ~= "userdata" then
        return nil
    end
    
    local success, result = pcall(function()
        -- Создаем уникальное имя файла
        local timestamp = os.time()
        local filename = string.format("%s_%d.png", app_name or "unknown", timestamp)
        local filepath = IconCache.cache_dir .. filename
        
        -- Конвертируем userdata в surface
        local surface = gears.surface(userdata_icon)
        
        -- Сохраняем как PNG
        surface:write_to_png(filepath)
        
        -- Сохраняем в кэше
        IconCache.cache[tostring(userdata_icon)] = filepath
        
        return filepath
    end)
    
    if success then
        return result
    else
        return nil
    end
end

function IconCache.get_icon_path(icon, app_name)
    if type(icon) == "string" then
        return icon -- Уже путь к файлу
    elseif type(icon) == "userdata" then
        -- Проверяем кэш
        local cached = IconCache.cache[tostring(icon)]
        if cached then
            return cached
        end
        
        -- Сохраняем в кэш
        return IconCache.save_userdata_icon(icon, app_name)
    end
    
    return nil
end

-- Инициализируем при загрузке
IconCache.init()

return IconCache
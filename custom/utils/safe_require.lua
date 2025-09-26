-- ~/.config/awesome/custom/utils/safe_require.lua
local naughty = require("naughty")
local wibox = require("wibox")
local debug_logger = require("custom.utils.debug_logger")

local SafeRequire = {}

function SafeRequire.require(module_path)
    debug_logger.log("SAFE_REQUIRE: пытаемся загрузить " .. module_path)
    local success, result = pcall(require, module_path)
    
    if success then
        debug_logger.log("SAFE_REQUIRE: успешно загружен " .. module_path)
        return result
    else
        debug_logger.log("SAFE_REQUIRE: ОШИБКА загрузки " .. module_path .. ": " .. tostring(result))
        
        -- Показываем ошибку в уведомлении
        naughty.notify({
            title = "Module Load Error",
            text = "Failed to load: " .. module_path .. "\nError: " .. tostring(result),
            timeout = 10,
            urgency = "critical"
        })
        
        -- Возвращаем заглушку
        return {
            new = function() 
                return {
                    widget = wibox.widget.textbox("Error: " .. module_path)
                }
            end
        }
    end
end

return SafeRequire
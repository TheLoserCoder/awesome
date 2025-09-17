-- ~/.config/awesome/custom/utils/safe_require.lua
local naughty = require("naughty")
local wibox = require("wibox")

local SafeRequire = {}

function SafeRequire.require(module_path)
    local success, result = pcall(require, module_path)
    
    if success then
        return result
    else
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
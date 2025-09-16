-- ~/.config/awesome/custom/utils/debug_logger.lua
local gears = require("gears")

local DebugLogger = {}

local log_file = "/home/panic-attack/.config/awesome/debug.log"

function DebugLogger.log(message)
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    local log_entry = string.format("[%s] %s\n", timestamp, message)
    
    local file = io.open(log_file, "a")
    if file then
        file:write(log_entry)
        file:close()
    end
end

function DebugLogger.clear()
    local file = io.open(log_file, "w")
    if file then
        file:close()
    end
end

return DebugLogger
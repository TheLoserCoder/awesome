-- ~/.config/awesome/custom/utils/event_emitter.lua
local EventEmitter = {}

function EventEmitter.new()
    local self = {}
    self.listeners = {}
    
    function self:on(event, callback)
        -- Отладка: проверяем тип callback
        local naughty = require("naughty")
        naughty.notify({
            title = "EventEmitter Debug",
            text = "Event: " .. tostring(event) .. "\nCallback type: " .. type(callback),
            timeout = 3
        })
        
        if type(callback) ~= "function" then
            naughty.notify({
                title = "EventEmitter Error",
                text = "Callback is not a function! Type: " .. type(callback) .. "\nValue: " .. tostring(callback),
                timeout = 5,
                urgency = "critical"
            })
            return
        end
        
        if not self.listeners[event] then
            self.listeners[event] = {}
        end
        table.insert(self.listeners[event], callback)
    end
    
    function self:emit(event, ...)
        if self.listeners[event] then
            for _, callback in ipairs(self.listeners[event]) do
                callback(...)
            end
        end
    end
    
    return self
end

return EventEmitter
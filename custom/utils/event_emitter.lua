-- ~/.config/awesome/custom/utils/event_emitter.lua
local EventEmitter = {}

function EventEmitter.new()
    local self = {}
    self.listeners = {}
    
    function self:on(event, callback)
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
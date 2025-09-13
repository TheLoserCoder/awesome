-- ~/.config/awesome/custom/utils/animate.lua
local rubato = require("custom.utils.rubato")

local Animate = {}
Animate.__index = Animate

-- Создание новой анимации (простая обертка для rubato.timed)
function Animate.new(config)
    config = config or {}
    local self = setmetatable({}, Animate)
    
    -- Создаем rubato.timed напрямую
    self.timed = rubato.timed {
        duration = config.duration or 0.3,
        intro = config.intro or 0.1,
        subscribed = config.subscribed or function() end
    }
    
    return self
end

-- Установка целевого значения
function Animate:to(target)
    self.timed.target = target
end

-- Получение текущего значения
function Animate:get_pos()
    return self.timed.pos
end

-- Пауза анимации
function Animate:pause()
    if self.timed.pause then
        self.timed:pause()
    end
end

return Animate
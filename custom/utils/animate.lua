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
        intro = config.intro or 0.1
    }
    
    -- Подписываемся безопасно через :subscribe
    if type(config.subscribed) == "function" then
        self.timed:subscribe(config.subscribed)
    end
    
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

-- Создание анимации для скролла
function Animate.scroll(config)
    config = config or {}
    local duration = config.duration or 0.3
    
    local anim = rubato.timed {
        intro = 0.05, -- ускорение
        outro = 0.05, -- замедление
        duration = 0.1 -- общее время перехода
    }
    
    -- Подписываемся безопасно через :subscribe
    if type(config.subscribed) == "function" then
        anim:subscribe(config.subscribed)
    end
    
    return anim
end

-- Функция для расчета количества кадров
function Animate.get_frame_count(duration, rate)
    duration = duration or 0.15
    rate = rate or 60
    return math.ceil(duration * rate)
end

-- Создание анимации для позиции (для taglist индикатора)
function Animate.position(config)
    config = config or {}
    
    local duration = config.duration or 0.22
    local intro = config.intro or 0.05
    local outro = config.outro or 0.05
    
    -- Проверяем, что intro + outro <= duration
    if intro + outro > duration then
        intro = duration * 0.2
        outro = duration * 0.2
    end
    
    local anim = rubato.timed {
        duration = duration,
        pos = config.initial_pos or 0,
        intro = intro,
        outro = outro
    }
    
    -- Подписываемся безопасно через :subscribe
    if type(config.subscribed) == "function" then
        anim:subscribe(config.subscribed)
    end
    
    -- Сохраняем ended callback как свойство
    if config.ended then
        anim.ended_callback = config.ended
        anim.duration_ms = duration * 1000
    end
    
    return anim
end

return Animate
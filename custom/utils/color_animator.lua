-- ~/.config/awesome/custom/utils/color_animator.lua
local rubato = require("custom.utils.rubato")

local ColorAnimator = {}
ColorAnimator.__index = ColorAnimator

-- Функция для конвертации HEX в RGBA
local function hex_to_rgba(hex)
    hex = hex:gsub("#","")
    local r = tonumber(hex:sub(1,2),16)
    local g = tonumber(hex:sub(3,4),16)
    local b = tonumber(hex:sub(5,6),16)
    local a = 255
    if #hex == 8 then
        a = tonumber(hex:sub(7,8),16)
    end
    return r, g, b, a
end

-- Функция для конвертации RGBA в HEX
local function rgba_to_hex(r,g,b,a)
    -- Округляем и ограничиваем значения
    r = math.max(0, math.min(255, math.floor(r + 0.5)))
    g = math.max(0, math.min(255, math.floor(g + 0.5)))
    b = math.max(0, math.min(255, math.floor(b + 0.5)))
    a = a and math.max(0, math.min(255, math.floor(a + 0.5))) or 255
    
    if a < 255 then
        return string.format("#%02X%02X%02X%02X", r, g, b, a)
    else
        return string.format("#%02X%02X%02X", r, g, b)
    end
end

function ColorAnimator.new(config)
    config = config or {}
    local self = setmetatable({}, ColorAnimator)
    
    self.duration = config.duration or 0.3
    self.easing = config.easing or rubato.quadratic
    self.callback = config.callback or function() end
    
    -- Начальный цвет
    self.from_color = config.from_color or "#000000"
    local r1, g1, b1, a1 = hex_to_rgba(self.from_color)
    
    -- Создаем анимации для RGBA компонентов
    self.r_anim = rubato.timed { 
        duration = self.duration, 
        pos = r1, 
        easing = self.easing 
    }
    self.g_anim = rubato.timed { 
        duration = self.duration, 
        pos = g1, 
        easing = self.easing 
    }
    self.b_anim = rubato.timed { 
        duration = self.duration, 
        pos = b1, 
        easing = self.easing 
    }
    self.a_anim = rubato.timed { 
        duration = self.duration, 
        pos = a1, 
        easing = self.easing 
    }
    
    -- Подписываемся на обновления
    self.r_anim:subscribe(function()
        self:_update_color()
    end)
    
    return self
end

function ColorAnimator:_update_color()
    local r = math.floor(self.r_anim.pos)
    local g = math.floor(self.g_anim.pos)
    local b = math.floor(self.b_anim.pos)
    local a = math.floor(self.a_anim.pos)
    local color = rgba_to_hex(r, g, b, a)
    self.callback(color)
end

function ColorAnimator:animate_to(to_color)
    local r2, g2, b2, a2 = hex_to_rgba(to_color)
    self.r_anim.target = r2
    self.g_anim.target = g2
    self.b_anim.target = b2
    self.a_anim.target = a2
end

function ColorAnimator:set_color(color)
    local r, g, b, a = hex_to_rgba(color)
    self.r_anim.pos = r
    self.g_anim.pos = g
    self.b_anim.pos = b
    self.a_anim.pos = a
    self.r_anim.target = r
    self.g_anim.target = g
    self.b_anim.target = b
    self.a_anim.target = a
end

return ColorAnimator
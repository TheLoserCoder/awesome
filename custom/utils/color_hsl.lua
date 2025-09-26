-- ~/.config/awesome/custom/utils/color_hsl.lua
local ColorHSL = {}
ColorHSL.__index = ColorHSL

-- HEX (#RRGGBB или #RRGGBBAA) → RGB + Alpha (0-255)
function ColorHSL.hex_to_rgb(hex)
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

-- RGB (0-255) → HEX (#RRGGBB или #RRGGBBAA)
function ColorHSL.rgb_to_hex(r, g, b, a)
    r = math.max(0, math.min(255, math.floor(r+0.5)))
    g = math.max(0, math.min(255, math.floor(g+0.5)))
    b = math.max(0, math.min(255, math.floor(b+0.5)))
    a = a and math.max(0, math.min(255, math.floor(a+0.5))) or 255
    if a < 255 then
        return string.format("#%02X%02X%02X%02X", r, g, b, a)
    else
        return string.format("#%02X%02X%02X", r, g, b)
    end
end

-- RGB (0-255) → HSL (h:0-360, s:0-1, l:0-1)
function ColorHSL.rgb_to_hsl(r, g, b)
    r, g, b = r/255, g/255, b/255
    local maxc = math.max(r,g,b)
    local minc = math.min(r,g,b)
    local h, s, l = 0,0,(maxc+minc)/2

    if maxc ~= minc then
        local d = maxc - minc
        s = l > 0.5 and d/(2-maxc-minc) or d/(maxc+minc)
        if maxc == r then
            h = (g-b)/d + (g < b and 6 or 0)
        elseif maxc == g then
            h = (b-r)/d + 2
        else
            h = (r-g)/d + 4
        end
        h = h * 60
    end

    return h, s, l
end

-- HSL → RGB (0-255)
function ColorHSL.hsl_to_rgb(h, s, l)
    local function hue_to_rgb(p, q, t)
        if t < 0 then t = t + 1 end
        if t > 1 then t = t - 1 end
        if t < 1/6 then return p + (q-p)*6*t end
        if t < 1/2 then return q end
        if t < 2/3 then return p + (q-p)*(2/3-t)*6 end
        return p
    end

    local r, g, b
    if s == 0 then
        r, g, b = l, l, l
    else
        local q = l < 0.5 and l*(1+s) or l+s-l*s
        local p = 2*l - q
        r = hue_to_rgb(p,q,h/360 + 1/3)
        g = hue_to_rgb(p,q,h/360)
        b = hue_to_rgb(p,q,h/360 - 1/3)
    end

    return r*255, g*255, b*255
end

-- HEX → HSL (0-360,0-1,0-1) + alpha
function ColorHSL.hex_to_hsl(hex)
    local r,g,b,a = ColorHSL.hex_to_rgb(hex)
    local h,s,l = ColorHSL.rgb_to_hsl(r,g,b)
    return h,s,l,a
end

-- HSL + alpha → HEX
function ColorHSL.hsl_to_hex(h,s,l,a)
    local r,g,b = ColorHSL.hsl_to_rgb(h,s,l)
    return ColorHSL.rgb_to_hex(r,g,b,a)
end

-- Интерполяция HSL (h1,s1,l1,a1 → h2,s2,l2,a2), t=0..1
function ColorHSL.lerp_hsl(h1,s1,l1,a1,h2,s2,l2,a2,t)
    -- Интерполяция hue с учётом перехода через 360°
    local dh = h2 - h1
    if dh > 180 then dh = dh - 360 end
    if dh < -180 then dh = dh + 360 end
    local h = (h1 + dh*t) % 360
    local s = s1 + (s2 - s1)*t
    local l = l1 + (l2 - l1)*t
    local a = a1 + (a2 - a1)*t
    return h,s,l,a
end

return ColorHSL
-- ~/.config/awesome/custom/widgets/base_widgets/background.lua
local wibox = require("wibox")
local gears = require("gears")
local BaseWidget = require("custom.widgets.base_widgets.base_widget")
local ColorHSL = require("custom.utils.color_hsl")

local Background = {}
Background.__index = Background
setmetatable(Background, {__index = BaseWidget})

function Background.new(args)
    args = args or {}

    local self = setmetatable(wibox.container.background(args), Background)
    

    
    BaseWidget.new(self, args)
    
    self._theme_color = args.theme_color or args.bg_type or "background"
    
    local function get_theme_bg()
        if beautiful and beautiful[self._theme_color] then
            return beautiful[self._theme_color]
        elseif beautiful and beautiful.background then
            return beautiful.background
        else
            return "#1E1E2E"
        end
    end
    
    self._original_bg = args.bg or get_theme_bg()
    
    -- Обновляем цвет при смене темы
    awesome.connect_signal("theme::changed", function()
        if not args.bg then -- Только если цвет не задан явно
            self._original_bg = get_theme_bg()
            self:set_bg(self._original_bg)
        end
    end)
    self._original_border_color = args.border_color
    
    -- Явно устанавливаем фон
    if self._original_bg then
        self:set_bg(self._original_bg)
    end
    
    -- Отложенная инициализация если beautiful не готов
    if not beautiful or not beautiful[self._theme_color] then
        gears.timer.delayed_call(function()
            if not args.bg and beautiful and beautiful[self._theme_color] then
                self._original_bg = beautiful[self._theme_color]
                self:set_bg(self._original_bg)
            end
        end)
    end
    
    if self._themed then
        self:set_theme_handler(function(_, t, prev_theme, next_theme)
            if self._original_bg then
                local from_bg = prev_theme[self._theme_color] or self._original_bg
                local to_bg = next_theme[self._theme_color] or self._original_bg
                
                local h1,s1,l1,a1 = ColorHSL.hex_to_hsl(from_bg)
                local h2,s2,l2,a2 = ColorHSL.hex_to_hsl(to_bg)
                
                local h,s,l,a = ColorHSL.lerp_hsl(h1,s1,l1,a1, h2,s2,l2,a2, t)
                local new_color = ColorHSL.hsl_to_hex(h,s,l,a)

                self:set_bg(new_color)
                
                if t >= 1 then
                    self._original_bg = to_bg
                end
            end
            
            if self._original_border_color then
                local from_border = prev_theme.accent or self._original_border_color
                local to_border = next_theme.accent or self._original_border_color
                
                local h1,s1,l1,a1 = ColorHSL.hex_to_hsl(from_border)
                local h2,s2,l2,a2 = ColorHSL.hex_to_hsl(to_border)
                
                local h,s,l,a = ColorHSL.lerp_hsl(h1,s1,l1,a1, h2,s2,l2,a2, t)
                self:set_border_color(ColorHSL.hsl_to_hex(h,s,l,a))
                
                if t >= 1 then
                    self._original_border_color = to_border
                end
            end
        end)
    end
    
    return self
end

return Background
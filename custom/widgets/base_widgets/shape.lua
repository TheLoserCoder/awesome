-- ~/.config/awesome/custom/widgets/base_widgets/shape.lua
local wibox = require("wibox")
local BaseWidget = require("custom.widgets.base_widgets.base_widget")

local Shape = {}
Shape.__index = Shape
setmetatable(Shape, {__index = BaseWidget})

function Shape.new(args)
    args = args or {}
    local self = setmetatable(wibox.container.background(), Shape)
    
    BaseWidget.new(self)
    
    self._original_bg = args.bg
    self._original_border_color = args.border_color
    self._shape = args.shape
    
    if self._original_bg then
        self:set_bg(self._original_bg)
    end
    if self._original_border_color then
        self:set_border_color(self._original_border_color)
    end
    if self._shape then
        self:set_shape(self._shape)
    end
    
    self:set_theme_handler(function(_, t, prev_theme, next_theme)
        local ColorHSL = require("custom.utils.color_hsl")
        
        if self._original_bg then
            local from_bg = prev_theme.bg_normal or self._original_bg
            local to_bg = next_theme.bg_normal or self._original_bg
            
            local h1,s1,l1,a1 = ColorHSL.hex_to_hsl(from_bg)
            local h2,s2,l2,a2 = ColorHSL.hex_to_hsl(to_bg)
            
            local h,s,l,a = ColorHSL.lerp_hsl(h1,s1,l1,a1, h2,s2,l2,a2, t)
            self:set_bg(ColorHSL.hsl_to_hex(h,s,l,a))
        end
        
        if self._original_border_color then
            local from_border = prev_theme.border_normal or self._original_border_color
            local to_border = next_theme.border_normal or self._original_border_color
            
            local h1,s1,l1,a1 = ColorHSL.hex_to_hsl(from_border)
            local h2,s2,l2,a2 = ColorHSL.hex_to_hsl(to_border)
            
            local h,s,l,a = ColorHSL.lerp_hsl(h1,s1,l1,a1, h2,s2,l2,a2, t)
            self:set_border_color(ColorHSL.hsl_to_hex(h,s,l,a))
        end
    end)
    
    return self
end

return Shape
-- ~/.config/awesome/custom/widgets/base_widgets/text.lua
local wibox = require("wibox")
local BaseWidget = require("custom.widgets.base_widgets.base_widget")
local beautiful = require("beautiful")


local Text = {}
Text.__index = Text
setmetatable(Text, {__index = BaseWidget})

function Text.new(args)
    args = args or {}
    local self = setmetatable(wibox.widget.textbox(), Text)
    
    BaseWidget.new(self, args)
    
    self._text = args.text or ""
    self._font = args.font
    self._theme_color = args.theme_color or "text"
    self._themed = args.themed ~= false
    
    -- Получаем цвет из beautiful по названию или используем fallback
    local function get_theme_color()
        if beautiful and beautiful[self._theme_color] then
            return beautiful[self._theme_color]
        elseif beautiful and beautiful.text then
            return beautiful.text
        else
            return "#ECEFF4"
        end
    end
    
    self._original_color = args.color or get_theme_color()
    
    -- Обновляем цвет при смене темы
    awesome.connect_signal("theme::changed", function()
        if not args.color then -- Только если цвет не задан явно
            self._original_color = get_theme_color()
            if self._text ~= "" then
                self:_update_markup()
            end
        end
    end)
    
    if self._text ~= "" then
        self:_update_markup()
    end
    
    -- Отложенная инициализация если beautiful не готов
    if not beautiful or not beautiful[self._theme_color] then
        local gears = require("gears")
        gears.timer.delayed_call(function()
            if not args.color and beautiful and beautiful[self._theme_color] then
                self._original_color = beautiful[self._theme_color]
                if self._text ~= "" then
                    self:_update_markup()
                end
            end
        end)
    end
    
    if self._themed then
        self:set_theme_handler(function(_, t, prev_theme, next_theme)
            local from_color = prev_theme[self._theme_color]
            local to_color = next_theme[self._theme_color]
            
            if from_color and to_color then
                local ColorHSL = require("custom.utils.color_hsl")
                local h1,s1,l1,a1 = ColorHSL.hex_to_hsl(from_color)
                local h2,s2,l2,a2 = ColorHSL.hex_to_hsl(to_color)
                local h,s,l,a = ColorHSL.lerp_hsl(h1,s1,l1,a1, h2,s2,l2,a2, t)
                local current_color = ColorHSL.hsl_to_hex(h,s,l,a)
                
                if t >= 1 then
                    self._original_color = to_color
                end
                
                if self._text ~= "" then
                    self:_update_markup(current_color)
                end
            end
        end)
    end
    
    return self
end

function Text:update_text(new_text)
    self._text = new_text or ""
    if self._text ~= "" then
        self:_update_markup()
    else
        self:set_markup("")
    end
end

function Text:_get_current_color()
    return self._original_color
end

function Text:update_color(new_color)
    if new_color then
        self._original_color = new_color
        if self._text ~= "" then
            self:_update_markup()
        end
    end
end

function Text:_update_markup(color)
    local current_color = color or self:_get_current_color()
    local markup = string.format('<span foreground="%s">%s</span>', current_color, self._text)
    
    if self._font then
        markup = string.format('<span font="%s" foreground="%s">%s</span>', self._font, current_color, self._text)
    end
    
    self:set_markup(markup)
end

return Text
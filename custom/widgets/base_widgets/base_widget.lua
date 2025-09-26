-- ~/.config/awesome/custom/widgets/base_widgets/base_widget.lua
local ThemeProvider = require("custom.theme.theme_provider")

local BaseWidget = {}
BaseWidget.__index = BaseWidget

function BaseWidget.new(self, args)
    args = args or {}
    self = self or setmetatable({}, BaseWidget)
    
    self._theme_handler = nil
    self._themed = args.themed ~= false -- по умолчанию true, если не задано явно false
    self._last_theme_t = nil -- защита от повторных вызовов
    
    self._provider_listener = function(t, prev_theme, next_theme)
        -- Защита от повторных вызовов с тем же значением t
        if self._last_theme_t == t then
            return
        end
        self._last_theme_t = t
        
        if self._themed and self._theme_handler then
            local ok, err = pcall(self._theme_handler, self, t, prev_theme, next_theme)
            if not ok then


            end
        end
    end
    
    ThemeProvider.get():subscribe(self._provider_listener)
    
    return self
end

function BaseWidget:set_theme_handler(handler)


    self._theme_handler = handler
end

function BaseWidget:destroy()
    if self._provider_listener then
        ThemeProvider.get():unsubscribe(self._provider_listener)
        self._theme_handler = nil
    end
end

return BaseWidget
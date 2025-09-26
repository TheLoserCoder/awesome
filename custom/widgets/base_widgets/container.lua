-- ~/.config/awesome/custom/widgets/base_widgets/container.lua
local wibox = require("wibox")
local Background = require("custom.widgets.base_widgets.background")
local gears = require("gears")
local settings = require("custom.settings")

local Container = {}
Container.__index = Container

function Container.new(config)
    config = config or {}
    
    -- Устанавливаем bg из beautiful по theme_color если не задан явно
    if not config.bg and config.theme_color then
        local beautiful = require("beautiful")
        if beautiful and beautiful[config.theme_color] then
            config.bg = beautiful[config.theme_color]
        end
    end
    
    local background = Background.new({
        bg = config.bg,
        theme_color = config.theme_color or config.bg_type,
        themed = config.themed,
        forced_width = config.width,
        forced_height = config.height,
        widget = wibox.widget {
            {
                config.content,
                halign = config.halign or "center",
                valign = config.valign or "center",
                widget = wibox.container.place
            },
            margins = config.margins,
            widget = wibox.container.margin
        }
    })
    

    
    local self = setmetatable(wibox.widget {
        widget = background,
        shape = config.shape,
       
    }, Container)
    
    self._background = background
    
    return self
end

function Container:set_bg(color)
    if self._background then
        self._background:set_bg(color)
    end
end

function Container:connect_signal(signal, callback)
    if self._background then
        self._background:connect_signal(signal, callback)
    end
end

-- Фабрики контейнеров
Container.round = function(config)
    config = config or {}
    config.shape = config.shape or settings.theme.shape or gears.shape.rounded_rect
    return Container.new(config)
end

Container.background = function(config)
    config = config or {}
    config.theme_color = "background"
    -- Устанавливаем bg из beautiful если не задан явно
    if not config.bg then
        local beautiful = require("beautiful")
        config.bg = (beautiful and beautiful.background) or "#1E1E2E"
    end
    return Container.round(config)
end

Container.surface = function(config)
    config = config or {}
    config.theme_color = "surface"
    -- Устанавливаем bg из beautiful если не задан явно
    if not config.bg then
        local beautiful = require("beautiful")
        config.bg = (beautiful and beautiful.surface) or "#2A2A3C"
    end
    return Container.round(config)
end

return Container
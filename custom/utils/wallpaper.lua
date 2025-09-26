-- ~/.config/awesome/custom/utils/wallpaper.lua
local gears = require("gears")
local awful = require("awful")
local beautiful = require("beautiful")

local settings = require("custom.settings")

local Wallpaper = {}

function Wallpaper.set()
    for s in screen do
        gears.wallpaper.maximized(settings.paths.wallpaper, s)
    end
end

-- Слушатель изменения темы
awesome.connect_signal("theme::changed", function(theme)


    
    if theme and theme.wallpaper then

        for s in screen do
            gears.wallpaper.maximized(theme.wallpaper, s)
        end
    else

    end
end)

return Wallpaper
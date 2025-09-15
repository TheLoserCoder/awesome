-- ~/.config/awesome/custom/utils/wallpaper.lua
local gears = require("gears")
local awful = require("awful")

local settings = require("custom.settings")

local Wallpaper = {}

function Wallpaper.set()
    for s in screen do
        gears.wallpaper.maximized(settings.paths.wallpaper, s)
    end
end

return Wallpaper
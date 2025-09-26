-- ~/.config/awesome/custom/widgets/layoutbox.lua
local awful = require("awful")

local Layoutbox = {}
Layoutbox.__index = Layoutbox

function Layoutbox.new(screen)
    local self = setmetatable({}, Layoutbox)
    
    -- Используем ванильный layoutbox
    self.widget = awful.widget.layoutbox(screen)
    
    -- Добавляем обработчики кнопок мыши
    local gears = require("gears")
    self.widget:buttons(gears.table.join(
        awful.button({ }, 1, function () awful.layout.inc( 1) end),
        awful.button({ }, 3, function () awful.layout.inc(-1) end),
        awful.button({ }, 4, function () awful.layout.inc( 1) end),
        awful.button({ }, 5, function () awful.layout.inc(-1) end)
    ))
    
    return self
end

return Layoutbox
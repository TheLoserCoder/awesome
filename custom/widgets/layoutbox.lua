-- ~/.config/awesome/custom/widgets/layoutbox.lua
local gears = require("gears")
local awful = require("awful")

local Layoutbox = {}
Layoutbox.__index = Layoutbox

local Button = require("custom.widgets.button")

function Layoutbox.new(screen)
    local self = setmetatable({}, Layoutbox)
    
    -- Создаем стандартный layoutbox
    local layoutbox = awful.widget.layoutbox(screen)
    
    -- Оборачиваем в кнопку
    self.button = Button.new({
        content = layoutbox,
        width = 28,
        height = 28,
        shape = gears.shape.rounded_rect,
        on_click = function()
            awful.layout.inc(1)
        end
    })
    
    -- Добавляем дополнительные кнопки мыши
    self.button.widget:buttons(gears.table.join(
        awful.button({ }, 1, function () awful.layout.inc( 1) end),
        awful.button({ }, 3, function () awful.layout.inc(-1) end),
        awful.button({ }, 4, function () awful.layout.inc( 1) end),
        awful.button({ }, 5, function () awful.layout.inc(-1) end)
    ))
    
    self.widget = self.button.widget
    
    return self
end

return Layoutbox
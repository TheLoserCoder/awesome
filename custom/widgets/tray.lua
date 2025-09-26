-- ~/.config/awesome/custom/widgets/tray.lua
local wibox = require("wibox")
local gears = require("gears")

local Tray = {}
Tray.__index = Tray

local Button2 = require("custom.widgets.button_2")
local Text = require("custom.widgets.base_widgets.text")
local Popup = require("custom.widgets.popup")
local settings = require("custom.settings")

function Tray.new()
    local self = setmetatable({}, Tray)
    
    -- Popup с треем
    local systray = wibox.widget.systray()
    systray.base_size = 16
    systray.horizontal = true
    
    self.popup = Popup.new({
        content = wibox.widget {
            {
                systray,
                widget = wibox.container.margin
            },
            forced_height = 16,
            forced_width = 100,
            bg = settings.colors.background,
            shape = function(cr, w, h)
                gears.shape.rounded_rect(cr, w, h, settings.dimensions.corner_radius)
            end,
            widget = wibox.container.background
        },
        preferred_positions = "bottom",
        preferred_anchors = "middle",
        offset = { y = 5 }
    })
    
    -- Кнопка с иконкой
    self.button = Button2.new({
        content = Text.new({
            text = settings.icons.system.tray,
            font = settings.fonts.icon .. " 12"
        }),
        on_click = function()
            self.popup:toggle()
        end
    })
    
    self.widget = self.button.widget
    self.popup:bind_to_widget(self.widget)
    
    return self
end

return Tray
-- ~/.config/awesome/custom/widgets/popup.lua
local gears = require("gears")
local wibox = require("wibox")
local awful = require("awful")

local Popup = {}
Popup.__index = Popup

local Provider = require("custom.widgets.provider")
local click_to_hide = require("custom.utils.click_to_hide")

function Popup.new(config)
    config = config or {}
    local self = setmetatable({}, Popup)
    
    local colors = Provider.get_colors()
    
    self.popup = awful.popup {
        widget = wibox.widget {
            {
                config.content or wibox.widget.textbox(""),
                margins = config.margins or 12,
                widget = wibox.container.margin
            },
            bg = colors.surface .. "60",
            shape = gears.shape.rounded_rect,
            widget = wibox.container.background
        },
        border_width = 0,
        bg = "#00000000",
        shape = gears.shape.rounded_rect,
        preferred_positions = config.preferred_positions or "bottom",
        preferred_anchors = config.preferred_anchors or "middle",
        offset = config.offset or { y = 5 },
        placement = config.placement,
        minimum_width = config.width,
        minimum_height = config.height,
        visible = false,
        ontop = true,
    }
    

    if config.click_to_hide ~= false then
        click_to_hide(self.popup)
    end
    
    return self
end

function Popup:bind_to_widget(widget)
    self.popup:bind_to_widget(widget)
end

function Popup:show()
    -- Принудительно обновляем геометрию перед показом
    gears.timer.delayed_call(function()
        self.popup.visible = true
    end)
end

function Popup:hide()
    self.popup.visible = false
end

function Popup:toggle()
    self.popup.visible = not self.popup.visible
end

function Popup:set_content(content)
    self.popup.widget:get_children()[1]:set_widget(content)
end

return Popup
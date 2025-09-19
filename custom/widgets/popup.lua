-- ~/.config/awesome/custom/widgets/popup.lua
local gears = require("gears")
local wibox = require("wibox")
local awful = require("awful")
local naughty = require("naughty")
local Popup = {}
Popup.__index = Popup

local Provider = require("custom.widgets.provider")
local click_to_hide_positioned = require("custom.utils.click_to_hide_positioned")
local EventEmitter = require("custom.utils.event_emitter")
local GlobalStorage = require("custom.utils.global_storage")

function Popup.new(config)
    config = config or {}
    local self = setmetatable({}, Popup)
    
    -- Добавляем EventEmitter как локальное свойство
    self._emitter = EventEmitter.new()
    
    local colors = Provider.get_colors()
    
    -- Сохраняем offset для последующего использования
    self.saved_offset = config.offset or { y = -2 }
    
    self.popup = awful.popup {
        widget = wibox.widget {
            {
                config.content or wibox.widget.textbox(""),
                margins = config.margins or 12,
                widget = wibox.container.margin
            },
            bg = config.bg or colors.surface .. "60",
            shape = gears.shape.rounded_rect,
            widget = wibox.container.background
        },
        border_width = 0,
        bg = "#00000000",
        shape = gears.shape.rounded_rect,
        preferred_positions = config.preferred_positions or "bottom",
        preferred_anchors = config.preferred_anchors or "middle",
        offset = self.saved_offset,
        placement = config.placement,
        minimum_width = config.width,
        minimum_height = config.height,
   
        x = -9999,
        y = -9999,
        ontop = false,
    }
    

    if config.click_to_hide ~= false then
        self.start_click_grabber = click_to_hide_positioned(self.popup, function()
            self:hide()
        end, function()
            return self._visible
        end)
    end
    
    return self
end

function Popup:bind_to_widget(widget)
    self.popup:bind_to_widget(widget)
end

function Popup:show()
    -- Позиционируем popup правильно
    self._visible = true
    self:emit("opened")
    if self.start_click_grabber then
        self.start_click_grabber()
    end
     self.popup.ontop = true
end

function Popup:hide()
    self.popup.visible = false
    self.popup.ontop = false
    self._visible = false
    
    gears.timer.start_new(0.2, function()
        self.popup.x = -9999
        self.popup.y = -9999
        self.popup.visible = true
        self:emit("closed")
        return false
    end)
end

function Popup:toggle()
    if self._visible then
        self:hide()
    else
        self:show()
    end
end

-- Свойство для проверки видимости
function Popup:get_visible()
    return self._visible
end

function Popup:set_content(content)
    self.popup.widget:get_children()[1]:set_widget(content)
end

-- Методы EventEmitter
function Popup:on(event, callback)

    if self._emitter then
        self._emitter:on(event, callback)
    end
end

function Popup:emit(event, ...)
    if self._emitter then
        self._emitter:emit(event, ...)
    end
end

return Popup
-- ~/.config/awesome/custom/widgets/keyboard_list.lua
local wibox = require("wibox")
local awful = require("awful")

local KeyboardList = {}
KeyboardList.__index = KeyboardList

function KeyboardList.new(config)
    local self = setmetatable({}, KeyboardList)
    
    self.items = {}
    self.selected_index = 1
    self.on_select = config.on_select
    self.on_submit = config.on_submit
    self.on_click = config.on_click
    self.keygrabber = nil
    self.button_config = config.button_config or {}
    self.is_visible = config.is_visible or function() return true end
    
    self.widget = wibox.widget {
        spacing = config.spacing or 2,
        layout = wibox.layout.fixed.vertical
    }
    
    return self
end

function KeyboardList:add_item(data, content_widget)
    local Button = require("custom.widgets.button")
    local index = #self.items + 1
    
    local button = Button.new({
        content = content_widget,
        width = self.button_config.width or 240,
        height = self.button_config.height or 32,
        halign = self.button_config.halign or "left",
        on_click = function()
            self:select_item(index)
            if self.on_click then
                self.on_click(data, index)
            end
        end
    })
    
    table.insert(self.items, {
        widget = button.widget,
        button = button,
        content = content_widget,
        data = data
    })
    
    self.widget:add(button.widget)
end

function KeyboardList:reset()
    self.widget:reset()
    self.items = {}
    self.selected_index = 1
end

function KeyboardList:select_item(index)
    if index < 1 or index > #self.items then return end
    
    self.selected_index = index
    if self.on_select then
        self.on_select(self.items[index].data, index)
    end
end

function KeyboardList:update_selection_style(selected_style, normal_style)
    for i, item in ipairs(self.items) do
        if i == self.selected_index then
            if item.button and item.button.set_bg then
                item.button:set_bg(selected_style.bg)
            end
            if item.content and selected_style.fg then
                item.content.fg = selected_style.fg
            end
        else
            if item.button and item.button.set_bg then
                item.button:set_bg(normal_style.bg)
            end
            if item.content and normal_style.fg then
                item.content.fg = normal_style.fg
            end
        end
    end
end

function KeyboardList:move_up()
    local new_index = self.selected_index - 1
    if new_index < 1 then new_index = #self.items end
    self:select_item(new_index)
end

function KeyboardList:move_down()
    local new_index = self.selected_index + 1
    if new_index > #self.items then new_index = 1 end
    self:select_item(new_index)
end

function KeyboardList:submit()
    if self.on_submit and #self.items > 0 then
        self.on_submit(self.items[self.selected_index].data, self.selected_index)
    end
end

function KeyboardList:select_first()
    if #self.items > 0 then
        self:select_item(1)
    end
end

function KeyboardList:start_keygrabber()
    if self.keygrabber then return end
    
    self.keygrabber = awful.keygrabber {
        keybindings = {
            awful.key({}, "Up", function() 
                if self.is_visible() then self:move_up() end 
            end),
            awful.key({}, "Down", function() 
                if self.is_visible() then self:move_down() end 
            end),
            awful.key({}, "k", function() 
                if self.is_visible() then self:move_up() end 
            end),
            awful.key({}, "j", function() 
                if self.is_visible() then self:move_down() end 
            end),
            awful.key({}, "Return", function() 
                if self.is_visible() then self:submit() end 
            end),
        },
        stop_key = "Escape",
        stop_callback = function()
            self.keygrabber = nil
        end
    }
    self.keygrabber:start()
end

function KeyboardList:stop_keygrabber()
    if self.keygrabber then
        self.keygrabber:stop()
        self.keygrabber = nil
    end
end

return KeyboardList
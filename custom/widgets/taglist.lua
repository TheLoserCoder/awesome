-- ~/.config/awesome/custom/widgets/taglist.lua
local gears = require("gears")
local awful = require("awful")
local wibox = require("wibox")

local Taglist = {}
Taglist.__index = Taglist

local Provider = require("custom.widgets.provider")
local Button = require("custom.widgets.button")

function Taglist.new(screen)
    local self = setmetatable({}, Taglist)
    
    local colors = Provider.get_colors()
    self.screen = screen
    
    self.buttons = {}
    self.layout = wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        spacing = 1
    }
    
    -- Создаем кнопки для каждого тега
    for i = 1, 9 do
        local tag = screen.tags[i]
        if tag then
            local button = Button.new({
                content = wibox.widget {
                    text = tostring(i),
                    align = "center",
                    valign = "center",
                    font = "Ubuntu Bold 10",
                    widget = wibox.widget.textbox
                },
                width = 20,
                height = 20,
                shape = gears.shape.circle,
                on_click = function()
                    tag:view_only()
                end
            })
            
            self.buttons[i] = button
            self.layout:add(button.widget)
            
            -- Обновляем стиль кнопки при изменении тега
            tag:connect_signal("property::selected", function()
                self:_update_all_buttons()
            end)
            
            tag:connect_signal("property::urgent", function()
                self:_update_button_style(i)
            end)
        end
    end
    
    -- Инициализируем стили кнопок
    self:_update_all_buttons()
    
    self.widget = self.layout
    
    return self
end

function Taglist:_update_button_style(index)
    local button = self.buttons[index]
    if not button then return end
    
    local colors = Provider.get_colors()
    local tag = self.screen.tags[index]
    
    if tag.selected then
        button:set_selected(true, colors.accent)
        -- Текст становится surface для контраста с акцентным фоном
        local content = button.widget:get_children()[1]:get_children()[1]:get_children()[1]
        if content and content.set_markup then
            content:set_markup('<span color="' .. colors.surface .. '">' .. content.text .. '</span>')
        end
    elseif tag.urgent then
        button:set_selected(false)
        button:set_bg(colors.error)
    else
        button:set_selected(false)
        button:set_bg(colors.surface)
        -- Сбрасываем цвет текста
        local content = button.widget:get_children()[1]:get_children()[1]:get_children()[1]
        if content and content.set_markup then
            content:set_markup('<span color="' .. colors.text .. '">' .. content.text .. '</span>')
        end
    end
end

function Taglist:_update_all_buttons()
    for i = 1, 9 do
        self:_update_button_style(i)
    end
end

return Taglist
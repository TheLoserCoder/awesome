-- ~/.config/awesome/custom/widgets/players_center.lua
local gears = require("gears")
local wibox = require("wibox")
local awful = require("awful")
local PlayersCenter = {}
PlayersCenter.__index = PlayersCenter

-- Получаем зависимости
local Button = require("custom.widgets.button")
local Popup = require("custom.widgets.popup")
local PlayersList = require("custom.widgets.players_list")
local settings = require("custom.settings")


-- Создание виджета центра плееров
function PlayersCenter.new(config)
    config = config or {}
    local self = setmetatable({}, PlayersCenter)
    
    
    
    self:_create_widgets()
    self.popup:bind_to_widget(self.widget)
    
    return self
end

-- Создание виджетов
function PlayersCenter:_create_widgets()
    local music_icon = wibox.widget {
        text = settings.icons.player.music,
        align = "center",
        valign = "center",
        font = "Font Awesome 6 Free 10",
        widget = wibox.widget.textbox
    }
    
    self.button = Button.new({
        content = music_icon,
        width = 24,
        height = 24,
        on_click = function()
            self:_toggle_popup()
        end
    })
    
    self.widget = self.button.widget
    
    
    self.players_list = PlayersList.new()
    
    
    -- Контейнер с фиксированной шириной
    local container = wibox.widget {
        self.players_list.widget,
        forced_width = 300,
        widget = wibox.container.constraint
    }
    
    self.popup = Popup.new({
        content = container,
        width = 300,
        height = 300
    })
    
    -- Передаем ссылку на popup в PlayersList
    self.players_list:set_popup(self.popup)
    

end

-- Переключение popup
function PlayersCenter:_toggle_popup()
    if not self.popup.visible then
        self.players_list:refresh()
    end
    self.popup:toggle()
end

return PlayersCenter
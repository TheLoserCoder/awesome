-- ~/.config/awesome/custom/widgets/players_list.lua
local wibox = require("wibox")
local gears = require("gears")
local awful = require("awful")
local PlayersList = {}
PlayersList.__index = PlayersList

local Player = require("custom.widgets.player")
local PlayerctlWrap = require("custom.utils.playerctl_wrap")

function PlayersList.new(config)
    config = config or {}
    local self = setmetatable({}, PlayersList)
    
    awful.spawn("notify-send 'PlayersList' 'Creating PlayersList'")
    
    self.players_widgets = {}
    self.playerctl = PlayerctlWrap.new()
    self.popup = nil -- Будет установлено из PlayersCenter
    
    self.layout = wibox.widget {
        layout = wibox.layout.fixed.vertical,
        spacing = config.spacing or 8
    }
    
    self.widget = self.layout -- Прямое использование layout без фиксированной высоты
    
    -- Настраиваем события
    self:_setup_signals()
    
    -- Отложенный пререндер после инициализации bling
    gears.timer.delayed_call(function()
        self:_initial_render()
    end)
    
    return self
end

function PlayersList:_setup_signals()
    -- Обновление метаданных
    self.playerctl:connect_signal("metadata", function(_, name, title, artist, art_url, pid)
        -- Добавляем плеер если его нет
        if not self.players_widgets[name] then
            self:_add_player_widget(name)
        end
        
        self:_update_player_widget(name, {
            title = title,
            artist = artist,
            album_art = art_url
        })
    end)
    
    -- Изменение статуса воспроизведения
    self.playerctl:connect_signal("playback_status", function(_, name, playing, pid)
        -- Добавляем плеер если его нет
        if not self.players_widgets[name] then
            self:_add_player_widget(name)
        end
        
        self:_update_player_widget(name, {
            is_playing = playing
        })
    end)
    

end

function PlayersList:_initial_render()
    local players = self.playerctl:get_players()
    
    if #players == 0 then
        self:_render_no_players()
        return
    end
    
    
    for _, player_info in ipairs(players) do
        self:_add_player_widget(player_info.name)
    end
end

function PlayersList:_add_player_widget(name)
    if self.players_widgets[name] then return end
    
    local data = self.playerctl:get_player_data(name)
    if data then
        self.players_widgets[name] = Player.new(name, data, self.playerctl, self.popup)
        self:_refresh_layout()
    end
end

function PlayersList:_remove_player_widget(name)
    if self.players_widgets[name] then
        self.players_widgets[name] = nil
        self:_refresh_layout()
    end
end

function PlayersList:_update_player_widget(name, updates)
    if self.players_widgets[name] then
        self.players_widgets[name]:update_data(updates)
    end
end

function PlayersList:_refresh_layout()
    self.layout:reset()
    
    local has_players = false
    for name, widget in pairs(self.players_widgets) do
        self.layout:add(widget.widget)
        has_players = true
    end
    
    if not has_players then
        self:_render_no_players()
    end
end

function PlayersList:_render_no_players()
    self.layout:reset()
    local no_players = wibox.widget {
        text = "No players found",
        align = "center",
        valign = "center",
        widget = wibox.widget.textbox
    }
    self.layout:add(no_players)
end

function PlayersList:set_popup(popup)
    self.popup = popup
    -- Обновляем существующие виджеты плееров
    for name, widget in pairs(self.players_widgets) do
        widget.popup = popup
    end
end

function PlayersList:refresh()
    local current_players = {}
    local players = self.playerctl:get_players()
    
    -- Собираем список активных плееров
    for _, player_info in ipairs(players) do
        current_players[player_info.name] = true
        -- Добавляем новые плееры
        if not self.players_widgets[player_info.name] then
            self:_add_player_widget(player_info.name)
        end
    end
    
    -- Удаляем неактивные плееры
    for name, _ in pairs(self.players_widgets) do
        if not current_players[name] then
            self:_remove_player_widget(name)
        end
    end
end

return PlayersList
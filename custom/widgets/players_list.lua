-- ~/.config/awesome/custom/widgets/players_list.lua
local wibox = require("wibox")
local gears = require("gears")
local awful = require("awful")
local PlayersList = {}
PlayersList.__index = PlayersList

local Player = require("custom.widgets.player")
local PlayerctlWrap = require("custom.utils.playerctl_wrap")
local settings = require("custom.settings")


  -- Прямое подключение к bling playerctl
    local bling = require("custom.utils.bling")
    local playerctl_lib = bling.signal.playerctl.lib()
    
    playerctl_lib:connect_signal("exit", function(_, player_name)
      
    end)

function PlayersList.new(config)
    config = config or {}
    local self = setmetatable({}, PlayersList)
    
    local debug_logger = require("custom.utils.debug_logger")
    debug_logger.log("PLAYERS_LIST: создаем PlayersList...")
    
    self.players_widgets = {}
    
    debug_logger.log("PLAYERS_LIST: создаем PlayerctlWrap...")
    local ok, playerctl = pcall(function()
        return PlayerctlWrap.new()
    end)
    
    if not ok then
        debug_logger.log("PLAYERS_LIST: Ошибка создания PlayerctlWrap: " .. tostring(playerctl))
        self.playerctl = nil
    else
        debug_logger.log("PLAYERS_LIST: PlayerctlWrap создан успешно")
        self.playerctl = playerctl
    end
    
    self.popup = nil
    
    self.layout = wibox.widget {
        layout = wibox.layout.fixed.vertical,
        spacing = settings.widgets.list_item.spacing
    }
    
    self.widget = self.layout
    
    if self.playerctl then
        debug_logger.log("PLAYERS_LIST: настраиваем сигналы...")
        self:_setup_signals()
        
        gears.timer.delayed_call(function()
            debug_logger.log("PLAYERS_LIST: запускаем начальный рендер...")
            self:_initial_render()
        end)
    else
        debug_logger.log("PLAYERS_LIST: PlayerctlWrap не создан, пропускаем сигналы")
    end
    
  
    

    
    return self
end

function PlayersList:_setup_signals()
    local debug_logger = require("custom.utils.debug_logger")
    debug_logger.log("PLAYERS_LIST: подключаем сигнал metadata...")
    
    self.playerctl:connect_signal("metadata", function(_, name, title, artist, art_url, pid)
        debug_logger.log("PLAYERS_LIST: получен metadata для " .. tostring(name))
        if not self.players_widgets[name] then
            self:_add_player_widget(name)
        end
        
        self:_update_player_widget(name, {
            title = title,
            artist = artist,
            album_art = art_url
        })
    end)
    
    self.playerctl:connect_signal("playback_status", function(_, name, playing, pid)
        if not self.players_widgets[name] then
            self:_add_player_widget(name)
        end
        
        self:_update_player_widget(name, {
            is_playing = playing
        })
    end)
    
    self.playerctl:connect_signal("player_exit", function(_, name)
        self:_remove_player_widget(name)
    end)
end

function PlayersList:_initial_render()
    local debug_logger = require("custom.utils.debug_logger")
    
    local ok, players = pcall(function()
        return self.playerctl:get_players()
    end)
    
    if not ok then
        debug_logger.log("PLAYERS_LIST: Ошибка получения плееров: " .. tostring(players))
        return
    end
    
    debug_logger.log("PLAYERS_LIST: найдено " .. #players .. " плееров")
    
    for _, player_info in ipairs(players) do
        debug_logger.log("PLAYERS_LIST: добавляем плеер " .. tostring(player_info.name))
        self:_add_player_widget(player_info.name)
    end
end

function PlayersList:_add_player_widget(name)
    if self.players_widgets[name] then return end
    
    local data = self.playerctl:get_player_data(name)
    if data then
        self.players_widgets[name] = Player.new(name, data, self.playerctl, self.popup)
        self.layout:add(self.players_widgets[name].widget)
        self.widget:emit_signal("widget::layout_changed")
    else
    end
end

function PlayersList:_remove_player_widget(name)
    if self.players_widgets[name] then
        self.layout:remove_widgets(self.players_widgets[name].widget)
        self.players_widgets[name] = nil
        self.widget:emit_signal("widget::layout_changed")
    end
end

function PlayersList:_update_player_widget(name, updates)
    if self.players_widgets[name] then
        self.players_widgets[name]:update_data(updates)
        self.widget:emit_signal("widget::layout_changed")
    end
end



function PlayersList:set_popup(popup)
    self.popup = popup
    for name, widget in pairs(self.players_widgets) do
        widget.popup = popup
    end
end

function PlayersList:refresh()
    local current_players = {}
    local players = self.playerctl:get_players()
    
    print("[PLAYERS_LIST] Refresh: found " .. #players .. " active players")
    
    for _, player_info in ipairs(players) do
        current_players[player_info.name] = true
        print("[PLAYERS_LIST] Active player: " .. tostring(player_info.name))
        if not self.players_widgets[player_info.name] then
            self:_add_player_widget(player_info.name)
        end
    end
    
    for name, _ in pairs(self.players_widgets) do
        if not current_players[name] then
            print("[PLAYERS_LIST] Removing inactive player: " .. tostring(name))
            self:_remove_player_widget(name)
        end
    end
end

return PlayersList
-- ~/.config/awesome/custom/widgets/players_list.lua
local wibox = require("wibox")
local gears = require("gears")
local awful = require("awful")
local PlayersList = {}
PlayersList.__index = PlayersList

local Player = require("custom.widgets.player")
local PlayerctlWrap = require("custom.utils.playerctl_wrap")
local settings = require("custom.settings")
local debug_logger = require("custom.utils.debug_logger")

  -- Прямое подключение к bling playerctl
    local bling = require("custom.utils.bling")
    local playerctl_lib = bling.signal.playerctl.lib()
    
    playerctl_lib:connect_signal("exit", function(_, player_name)
        debug_logger.log("[PLAYERS_LIST] Direct bling exit signal for: " .. tostring(player_name))
      
    end)

function PlayersList.new(config)
    config = config or {}
    local self = setmetatable({}, PlayersList)
    
    debug_logger.log("[PLAYERS_LIST] Creating PlayersList widget")
    
    self.players_widgets = {}
    self.playerctl = PlayerctlWrap.new()
    self.popup = nil
    
    self.layout = wibox.widget {
        layout = wibox.layout.fixed.vertical,
        spacing = settings.widgets.list_item.spacing
    }
    
    self.widget = self.layout
    
    self:_setup_signals()
    
    gears.timer.delayed_call(function()
        debug_logger.log("[PLAYERS_LIST] Starting initial render")
        self:_initial_render()
    end)
    
  
    

    
    return self
end

function PlayersList:_setup_signals()
    self.playerctl:connect_signal("metadata", function(_, name, title, artist, art_url, pid)
        debug_logger.log("[PLAYERS_LIST] Metadata signal for player: " .. tostring(name))
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
        debug_logger.log("[PLAYERS_LIST] Playback status signal for player: " .. tostring(name) .. ", playing: " .. tostring(playing))
        if not self.players_widgets[name] then
            self:_add_player_widget(name)
        end
        
        self:_update_player_widget(name, {
            is_playing = playing
        })
    end)
    
    self.playerctl:connect_signal("player_exit", function(_, name)
        debug_logger.log("[PLAYERS_LIST] Player exit signal for: " .. tostring(name))
        self:_remove_player_widget(name)
    end)
end

function PlayersList:_initial_render()
    local players = self.playerctl:get_players()
    
    debug_logger.log("[PLAYERS_LIST] Initial render found " .. #players .. " players")
    
    for _, player_info in ipairs(players) do
        debug_logger.log("[PLAYERS_LIST] Initial render adding: " .. tostring(player_info.name))
        self:_add_player_widget(player_info.name)
    end
end

function PlayersList:_add_player_widget(name)
    if self.players_widgets[name] then return end
    
    debug_logger.log("[PLAYERS_LIST] Adding player widget: " .. tostring(name))
    local data = self.playerctl:get_player_data(name)
    if data then
        self.players_widgets[name] = Player.new(name, data, self.playerctl, self.popup)
        self.layout:add(self.players_widgets[name].widget)
        self.widget:emit_signal("widget::layout_changed")
        debug_logger.log("[PLAYERS_LIST] Player widget added successfully: " .. tostring(name))
    else
        debug_logger.log("[PLAYERS_LIST] No data for player: " .. tostring(name))
    end
end

function PlayersList:_remove_player_widget(name)
    debug_logger.log("[PLAYERS_LIST] Attempting to remove player widget: " .. tostring(name))
    if self.players_widgets[name] then
        self.layout:remove_widgets(self.players_widgets[name].widget)
        self.players_widgets[name] = nil
        self.widget:emit_signal("widget::layout_changed")
        debug_logger.log("[PLAYERS_LIST] Player widget removed successfully: " .. tostring(name))
    else
        debug_logger.log("[PLAYERS_LIST] Player widget not found for removal: " .. tostring(name))
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
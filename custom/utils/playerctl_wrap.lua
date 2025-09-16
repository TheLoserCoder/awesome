-- ~/.config/awesome/custom/utils/playerctl_wrap.lua
local gobject = require("gears.object")
local gtable = require("gears.table")
local bling = require("custom.utils.bling")

local PlayerctlWrap = {}
PlayerctlWrap.__index = PlayerctlWrap

function PlayerctlWrap.new()
    local self = gobject{}
    gtable.crush(self, PlayerctlWrap, true)
    
    self.playerctl = bling.signal.playerctl.lib()
    
    -- Настраиваем события
    self:_setup_signals()
    
    return self
end

function PlayerctlWrap:_setup_signals()
    -- Метаданные
    self.playerctl:connect_signal("metadata", function(_, title, artist, album_path, album, new, player_name)
        self:emit_signal("metadata", player_name, title, artist, album_path)
    end)
    
    -- Статус воспроизведения
    self.playerctl:connect_signal("playback_status", function(_, playing, player_name)
        self:emit_signal("playback_status", player_name, playing)
    end)
    
    -- Появление плеера (через awesome сигналы)
    awesome.connect_signal("bling::playerctl::title_artist_album", function(title, artist, art_path, player_name)
        self:emit_signal("player_added", player_name)
    end)
end

function PlayerctlWrap:get_players()
    local manager = self.playerctl:get_manager()
    local list = {}
    
    if manager and manager.players then
        for _, player in ipairs(manager.players) do
            table.insert(list, {
                name = player.player_name,
                player = player
            })
        end
    end
    
    return list
end

function PlayerctlWrap:get_player_data(name)
    local player = self.playerctl:get_player_of_name(name)
    if not player then return nil end
    
    local metadata = player.metadata and player.metadata.value or {}
    local title = metadata["xesam:title"] or "Unknown"
    local artist_array = metadata["xesam:artist"] or {}
    local artist = artist_array[1] or "Unknown"
    local art_url = metadata["mpris:artUrl"] or ""
    
    return {
        name = name,
        title = title,
        artist = artist,
        album_art = art_url,
        is_playing = player.playback_status == "PLAYING"
    }
end

-- Управление плеером
function PlayerctlWrap:play(name)
    local player = self.playerctl:get_player_of_name(name)
    if player then
        self.playerctl:play(player)
    end
end

function PlayerctlWrap:pause(name)
    local player = self.playerctl:get_player_of_name(name)
    if player then
        self.playerctl:pause(player)
    end
end

function PlayerctlWrap:play_pause(name)
    local player = self.playerctl:get_player_of_name(name)
    if player then
        self.playerctl:play_pause(player)
    end
end

function PlayerctlWrap:next(name)
    local player = self.playerctl:get_player_of_name(name)
    if player then
        self.playerctl:next(player)
    end
end

function PlayerctlWrap:previous(name)
    local player = self.playerctl:get_player_of_name(name)
    if player then
        self.playerctl:previous(player)
    end
end

return PlayerctlWrap
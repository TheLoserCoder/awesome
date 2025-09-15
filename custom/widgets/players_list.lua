-- ~/.config/awesome/custom/widgets/players_list.lua
local wibox = require("wibox")
local awful = require("awful")

local PlayersList = {}
PlayersList.__index = PlayersList

local Player = require("custom.widgets.player")

function PlayersList.new(config)
    config = config or {}
    local self = setmetatable({}, PlayersList)
    
    self.players_widgets = {}
    
    self.layout = wibox.widget {
        layout = wibox.layout.fixed.vertical,
        spacing = config.spacing or 8
    }
    
    self.widget = self.layout
    
    return self
end

function PlayersList:render()
    awful.spawn.easy_async("playerctl --list-all", function(stdout)
        self.layout:reset()
        
        local has_players = false
        
        for player_name in stdout:gmatch("[^\n]+") do
            if player_name and player_name ~= "" then
                if not self.players_widgets[player_name] then
                    self.players_widgets[player_name] = Player.new(player_name)
                end
                
                self.layout:add(self.players_widgets[player_name].widget)
                has_players = true
            end
        end
        
        if not has_players then
            local no_players = wibox.widget {
                text = "No players found",
                align = "center",
                valign = "center",
                widget = wibox.widget.textbox
            }
            self.layout:add(no_players)
        end
    end)
end

return PlayersList
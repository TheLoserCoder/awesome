-- ~/.config/awesome/custom/widgets/player.lua
local gears = require("gears")
local wibox = require("wibox")
local awful = require("awful")

local Player = {}
Player.__index = Player

-- Получаем зависимости
local Button = require("custom.widgets.button")
local Provider = require("custom.widgets.provider")
local bling = require("custom.utils.bling")
local settings = require("custom.settings")

-- Создание виджета плеера
function Player.new(player_name)
    local self = setmetatable({}, Player)
    
    self.player_name = player_name
    self.title = "Unknown"
    self.artist = "Unknown"
    self.is_playing = false
    
    -- Создаем виджеты
    self:_create_widgets()
    self:_setup_bling_signals()
    self:_initial_update()
    
    return self
end

-- Создание виджетов
function Player:_create_widgets()
    local colors = Provider.get_colors()
    
    -- Информация о треке в одну строку
    self.track_widget = wibox.widget {
        {
            text = self.title .. " - " .. self.artist,
            align = "left",
            valign = "center",
            font = "Ubuntu Bold 10",
            ellipsize = "end",
            widget = wibox.widget.textbox
        },
        forced_height = 16,
        widget = wibox.container.constraint
    }
    
    self.player_widget = wibox.widget {
        {
            text = self.player_name,
            align = "left",
            valign = "center", 
            font = "Ubuntu 8",
            fg = colors.text_secondary,
            ellipsize = "end",
            widget = wibox.widget.textbox
        },
        forced_height = 12,
        widget = wibox.container.constraint
    }
    
    -- Кнопки управления
    self.prev_button = Button.new({
        content = wibox.widget {
            text = settings.icons.player.prev,
            align = "center",
            valign = "center",
            widget = wibox.widget.textbox
        },
        width = 20,
        height = 20,
        on_click = function()
            awful.spawn("playerctl --player=" .. self.player_name .. " previous", false)
        end
    })
    
    self.play_icon = wibox.widget {
        text = settings.icons.player.play,
        align = "center",
        valign = "center",
        widget = wibox.widget.textbox
    }
    
    self.play_button = Button.new({
        content = self.play_icon,
        width = 20,
        height = 20,
        on_click = function()
            awful.spawn("playerctl --player=" .. self.player_name .. " play-pause", false)
        end
    })
    
    self.next_button = Button.new({
        content = wibox.widget {
            text = settings.icons.player.next,
            align = "center",
            valign = "center",
            widget = wibox.widget.textbox
        },
        width = 20,
        height = 20,
        on_click = function()
            awful.spawn("playerctl --player=" .. self.player_name .. " next", false)
        end
    })
    

    
    -- Контейнер для кнопок
    local buttons_container = wibox.widget {
        self.prev_button.widget,
        self.play_button.widget,
        self.next_button.widget,
        spacing = 4,
        layout = wibox.layout.fixed.horizontal
    }
    
    -- Основной виджет
    self.widget = wibox.widget {
        self.track_widget,
        self.player_widget,
        buttons_container,
        spacing = 4,
        layout = wibox.layout.fixed.vertical
    }
end

-- Настройка Bling сигналов
function Player:_setup_bling_signals()
    -- Инициализируем Bling playerctl CLI
    self.playerctl = bling.signal.playerctl.cli()
    
    -- Таймер для периодического обновления
    gears.timer {
        timeout = 2.0,
        autostart = true,
        callback = function()
            self:_check_updates()
        end
    }
    
    -- Слушаем глобальные сигналы (любой плеер может измениться)
    self.playerctl:connect_signal("metadata", function(_, title, artist, album_path, album)
        self:_check_updates()
    end)
    
    self.playerctl:connect_signal("playback_status", function(_, playing)
        self:_check_updates()
    end)
end

-- Начальное обновление данных
function Player:_initial_update()
    self:_check_updates()
end

-- Проверка обновлений для конкретного плеера
function Player:_check_updates()
    -- Получаем метаданные
    awful.spawn.easy_async("playerctl --player=" .. self.player_name .. " metadata --format '{{title}}|{{artist}}'", function(meta_out)
        local parts = meta_out:match("^%s*(.-)%s*$")
        if parts and parts ~= "" then
            local title, artist = parts:match("^(.-)|(.-)$")
            self:_update_metadata(title, artist)
        end
    end)
    
    -- Получаем статус
    awful.spawn.easy_async("playerctl --player=" .. self.player_name .. " status", function(status_out)
        local status = status_out:gsub("%s+", ""):lower()
        local playing = (status == "playing")
        self:_update_status(playing)
    end)
end

-- Обновление метаданных
function Player:_update_metadata(title, artist)
    self.title = title and title ~= "" and title or "Unknown"
    self.artist = artist and artist ~= "" and artist or "Unknown"
    
    self.track_widget:get_children()[1].text = self.title .. " - " .. self.artist
end

-- Обновление статуса воспроизведения
function Player:_update_status(playing)
    self.is_playing = playing
    
    if self.is_playing then
        self.play_icon.text = settings.icons.player.pause
    else
        self.play_icon.text = settings.icons.player.play
    end
end

return Player
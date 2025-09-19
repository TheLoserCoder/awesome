-- ~/.config/awesome/custom/widgets/player.lua
local gears = require("gears")
local wibox = require("wibox")
local awful = require("awful")

local Player = {}
Player.__index = Player

-- Получаем зависимости
local Button = require("custom.widgets.button")
local Provider = require("custom.widgets.provider")
local Image = require("custom.widgets.image")
local WindowFocus = require("custom.utils.window_focus")
local settings = require("custom.settings")

-- Создание виджета плеера
function Player.new(player_name, initial_data, playerctl, popup, height)
    local self = setmetatable({}, Player)
    
    self.player_name = player_name
    self.playerctl = playerctl
    self.popup = popup
    
    if initial_data then
        self.title = initial_data.title or "Unknown"
        self.artist = initial_data.artist or "Unknown"
        self.is_playing = initial_data.is_playing or false
        self.album_art_url = initial_data.album_art or ""
    else
        self.title = "Unknown"
        self.artist = "Unknown"
        self.is_playing = false
        self.album_art_url = ""
    end
    
    -- Создаем виджеты с готовыми данными
    self:_create_widgets()
    
    return self
end

-- Создание виджетов
function Player:_create_widgets()
    local colors = Provider.get_colors()
    
    -- Источник плеера
    self.player_widget = wibox.widget {
        {
            markup = "<span color='" .. colors.text_muted .. "'>" .. self.player_name .. "</span>",
            align = "left",
            valign = "center", 
            font = "Ubuntu 7",
            ellipsize = "end",
            widget = wibox.widget.textbox
        },
        forced_height = 12,
        widget = wibox.container.constraint
    }
    
    -- Картинка альбома (квадратная, на всю высоту второй строки)
    self.album_art = Image.new({
        fallback_icon = settings.icons.player.music,
        width = 50,
        height = 50,
        shape = function(cr, w, h) gears.shape.rounded_rect(cr, w, h, settings.dimensions.corner_radius) end
    })
    
    -- Устанавливаем начальную обложку если есть
    if self.album_art_url and self.album_art_url ~= "" then
        self.album_art:set_source(self.album_art_url)
    end
    
    -- Информация о треке
    self.track_widget = wibox.widget {
        {
            text = self.title,
            align = "left",
            valign = "center",
            font = "Ubuntu Bold 10",
            ellipsize = "end",
            widget = wibox.widget.textbox
        },
        forced_height = 16,
        widget = wibox.container.constraint
    }
    
    self.artist_widget = wibox.widget {
        {
            text = self.artist,
            align = "left",
            valign = "center",
            font = "Ubuntu 9",
            fg = colors.text_secondary,
            ellipsize = "end",
            widget = wibox.widget.textbox
        },
        forced_height = 14,
        widget = wibox.container.constraint
    }
    
    -- Кнопки управления (уменьшенные)
    self.prev_button = Button.new({
        content = wibox.widget {
            text = settings.icons.player.prev,
            align = "center",
            valign = "center",
            font = "Font Awesome 6 Free 12",
            widget = wibox.widget.textbox
        },
        width = 28,
        height = 28,
        on_click = function()
            if self.playerctl then
                self.playerctl:previous(self.player_name)
            else
                awful.spawn("playerctl --player=" .. self.player_name .. " previous", false)
            end
        end
    })
    
    self.play_icon = wibox.widget {
        text = self.is_playing and settings.icons.player.pause or settings.icons.player.play,
        align = "center",
        valign = "center",
        font = "Font Awesome 6 Free 12",
        widget = wibox.widget.textbox
    }
    
    self.play_button = Button.new({
        content = self.play_icon,
        width = 28,
        height = 28,
        on_click = function()
            if self.playerctl then
                self.playerctl:play_pause(self.player_name)
            else
                awful.spawn("playerctl --player=" .. self.player_name .. " play-pause", false)
            end
        end
    })
    
    self.next_button = Button.new({
        content = wibox.widget {
            text = settings.icons.player.next,
            align = "center",
            valign = "center",
            font = "Font Awesome 6 Free 12",
            widget = wibox.widget.textbox
        },
        width = 28,
        height = 28,
        on_click = function()
            if self.playerctl then
                self.playerctl:next(self.player_name)
            else
                awful.spawn("playerctl --player=" .. self.player_name .. " next", false)
            end
        end
    })
    
    -- Контейнер для кнопок
    local buttons_container = wibox.widget {
        self.prev_button.widget,
        self.play_button.widget,
        self.next_button.widget,
        spacing = 6,
        layout = wibox.layout.fixed.horizontal
    }
    
    -- Второй столбец - информация о треке (ограничено 200px)
    local info_column = wibox.widget {
        {
            {
                {
                    self.track_widget,
                    self.artist_widget,
                    self.player_widget,
                    spacing = 2,
                    layout = wibox.layout.fixed.vertical
                },
                left = 8,
                widget = wibox.container.margin
            },
            valign = "center",
            halign = "left",
            widget = wibox.container.place
        },
        forced_width = 200,
        widget = wibox.container.constraint
    }
    
    -- Вторая строка с тремя столбцами
    local second_row = wibox.widget {
        {
            self.album_art.widget,
            valign = "center",
            widget = wibox.container.place
        },
        info_column,
        {
            buttons_container,
            valign = "center",
            halign = "right",
            widget = wibox.container.place
        },
        layout = wibox.layout.align.horizontal
    }
    
    -- Добавляем клик на картинку
    self.album_art.widget:buttons(gears.table.join(
        awful.button({}, 1, function()
            self:_focus_player_window()
        end)
    ))
    
    -- Добавляем клик на весь блок с информацией
    info_column:buttons(gears.table.join(
        awful.button({}, 1, function()
            self:_focus_player_window()
        end)
    ))
    
    -- Основной виджет с фоном и скруглениями
    self.widget = wibox.widget {
        {
            second_row,
            margins = 8,
            widget = wibox.container.margin
        },
        bg = colors.surface,
        forced_height = height or settings.widgets.list_item.height,
        shape = function(cr, w, h)
            gears.shape.rounded_rect(cr, w, h, settings.dimensions.corner_radius)
        end,
        widget = wibox.container.background
    }

end

-- Обновление данных плеера
function Player:update_data(data)
    if data.title and data.title ~= self.title then
        self.title = data.title
        self.track_widget:get_children()[1].text = self.title
    end
    
    if data.artist and data.artist ~= self.artist then
        self.artist = data.artist
        self.artist_widget:get_children()[1].text = self.artist
    end
    
    if data.is_playing ~= nil and data.is_playing ~= self.is_playing then
        self.is_playing = data.is_playing
        self.play_icon.text = self.is_playing and settings.icons.player.pause or settings.icons.player.play
    end
    
    if data.album_art and data.album_art ~= self.album_art_url then
        self.album_art_url = data.album_art
        self.album_art:set_source(self.album_art_url)
    end
end

-- Переключение на окно плеера
function Player:_focus_player_window()
    -- Закрываем popup перед переключением
    if self.popup and self.popup.popup.visible then
        self.popup:hide()
    end
    
    local success = WindowFocus.focus_by_name(self.player_name)
    if not success then
        WindowFocus.focus_by_class(self.player_name)
    end
end

return Player
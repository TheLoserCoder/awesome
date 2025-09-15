-- ~/.config/awesome/autostart.lua
local awful = require("awful")
local gears = require("gears")


local M = {}

-- Функция для старта и назначения клиента на тег
local function run_on_tag(cmd, tag_index)
    awful.spawn.once(cmd, {
        -- просто запускаем, переносим позже
    })

    client.connect_signal("manage", function(c)
        if c.class then
            -- проверяем приложение по имени класса
            if (cmd:match("firefox") and c.class:lower():match("firefox"))
            or (cmd:match("spotify") and c.class:lower():match("spotify"))
            or (cmd:match("Telegram") and c.class:lower():match("telegram")) then
                local t = screen[1].tags[tag_index]
                if t then
                    c:move_to_tag(t)
                    --5t:view_only() -- переключиться сразу на этот тэг (можно убрать, если не хочешь)
                end
            end
        end
    end)
end

function M.run()
    -- Клавиатура (us/ru/ua, переключение Alt+Shift)
    awful.spawn.once("setxkbmap -layout us,ru,ua -option grp:alt_shift_toggle")
	awful.spawn.once("playerctld daemon")
    awful.spawn.with_shell("copyq")

	--Запуск Dunst
	--awful.spawn.with_shell("pgrep -x dunst || dunst &")

    --Запуск Picom
    awful.spawn.with_shell("pgrep -x picom || picom --config ~/.config/picom/picom.conf --vsync &")

    -- Телеграм (appimage)
    run_on_tag("/home/panic-attack/Telegram/Telegram", 1)

    -- Spotify
    run_on_tag("spotify", 2)

    -- Firefox
    run_on_tag("firefox", 3)
end

return M


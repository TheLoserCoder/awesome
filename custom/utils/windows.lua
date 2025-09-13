local awful = require("awful")
local beautiful = require("beautiful")
local Windows = {}

function Windows.setupGaps()
    -- В rc.lua
    local gapsSize = 5

    -- Настройка gaps для конкретного layout
    beautiful.useless_gap = gapsSize
    beautiful.gap_single_client = true
end

function Windows.newWindowToTheEndOfWindowsList(client)
    client.connect_signal("manage", function(c)
        -- Проверяем, что окно новое и не подчиняется другим правилам
        if not c.size_hints.user_position and not c.size_hints.program_position then
            -- Получаем текущий тэг и список клиентов на нём
            local t = c.first_tag
            if t then
                -- Добавляем окно в конец
                c:move_to_tag(t)
                awful.client.setslave(c)  -- делает его "slave", чтобы появилось в конце
            end
        end
    end)
end

return Windows

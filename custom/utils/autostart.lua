-- ~/.config/awesome/autostart.lua
local awful = require("awful")
local gears = require("gears")
local settings = require("custom.settings")

local M = {}

-- Функция для старта и назначения клиента на тег
local function run_on_tag(cmd, tag_index)
    awful.spawn.with_shell(cmd)

    client.connect_signal("manage", function(c)
        if c.class then
            local tag_config = settings.widgets.taglist.tags[tag_index]
            if tag_config and tag_config.app_classes then
                -- проверяем приложение по списку классов из настроек
                for _, app_class in ipairs(tag_config.app_classes) do
                    if c.class:lower():match(app_class:lower()) then
                        local t = screen[1].tags[tag_index]
                        if t then
                            c:move_to_tag(t)
                        end
                        break
                    end
                end
            end
        end
    end)
end

function M.run()
    -- Общие команды автозапуска
    for _, cmd in ipairs(settings.autostart) do
        awful.spawn.with_shell(cmd)
    end
    
    -- Запуск приложений по тегам
    for i, tag_config in ipairs(settings.widgets.taglist.tags) do
        for _, cmd in ipairs(tag_config.autostart) do
            run_on_tag(cmd, i)
        end
    end
end

return M


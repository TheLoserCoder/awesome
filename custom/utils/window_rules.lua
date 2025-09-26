-- ~/.config/awesome/custom/utils/window_rules.lua
local awful = require("awful")
local beautiful = require("beautiful")
local settings = require("custom.settings")

local WindowRules = {}

-- Функция для обновления рамок окон в теге
local function update_borders_for_tag(tag)
    if not tag then return end
    
    local clients = tag:clients()
    local border_width = 2
    
    for _, c in pairs(clients) do
        if #clients == 1 then
            c.border_width = 0
        else
            c.border_width = border_width
            
            if c == client.focus then
                c.border_color = beautiful.border_focus or beautiful.accent or "#F5F5F5"
            else
                c.border_color = beautiful.border_normal or beautiful.transparent or "#00000000"
            end
        end
    end
end

-- Настройка сигналов для динамического управления рамками
local function setup_border_signals()
    -- При создании нового окна
    client.connect_signal("manage", function(c)
        local tag = c.first_tag or c.screen.selected_tag
        update_borders_for_tag(tag)
    end)
    
    -- При добавлении окна к тегу
    client.connect_signal("tagged", function(c, tag)
        update_borders_for_tag(tag)
    end)
    
    -- При удалении окна из тега
    client.connect_signal("untagged", function(c, tag)
        update_borders_for_tag(tag)
    end)
    
    -- При закрытии окна
    client.connect_signal("unmanage", function(c)
        local tag = c.screen.selected_tag
        update_borders_for_tag(tag)
    end)
    
    -- При смене фокуса
    client.connect_signal("focus", function(c)
        local tag = c.first_tag or c.screen.selected_tag
        update_borders_for_tag(tag)
    end)
    
    client.connect_signal("unfocus", function(c)
        local tag = c.first_tag or c.screen.selected_tag
        update_borders_for_tag(tag)
    end)
end

function WindowRules.setup()
    -- Правила для всех окон
    awful.rules.rules = {
        -- Правило для всех окон
        {
            rule = { },
            properties = {
                titlebars_enabled = false,
                border_width = settings.dimensions.border_width,
                border_color = beautiful.border_normal or beautiful.transparent or "#00000000",
                focus = awful.client.focus.filter,
                raise = true,
                keys = clientkeys,
                buttons = clientbuttons,
                screen = awful.screen.preferred,
                placement = awful.placement.no_overlap+awful.placement.no_offscreen
            }
        },
        
        -- Правила для плавающих окон
        {
            rule_any = {
                instance = {
                    "DTA",
                    "copyq",
                    "pinentry",
                },
                class = {
                    "Arandr",
                    "Blueman-manager",
                    "Gpick",
                    "Kruler",
                    "MessageWin",
                    "Sxiv",
                    "Tor Browser",
                    "Wpa_gui",
                    "veromix",
                    "xtightvncviewer"
                },
                name = {
                    "Event Tester",
                },
                role = {
                    "AlarmWindow",
                    "ConfigManager",
                    "pop-up",
                }
            },
            properties = { 
                floating = true,
                border_color = beautiful.border_focus or beautiful.accent or "#F5F5F5"
            }
        },
        
        -- Правила для полноэкранных приложений
        {
            rule_any = { type = { "normal", "dialog" } },
            properties = { titlebars_enabled = false }
        }
    }
    
    -- Настраиваем динамическое управление рамками
    setup_border_signals()
    
    -- Подписываемся на изменения темы для обновления цветов границ
    local ThemeProvider = require("custom.theme.theme_provider")
    ThemeProvider.get():subscribe(function()
        -- Обновляем границы всех окон на всех экранах
        for s in screen do
            for _, tag in ipairs(s.tags) do
                update_borders_for_tag(tag)
            end
        end
    end)
end

return WindowRules
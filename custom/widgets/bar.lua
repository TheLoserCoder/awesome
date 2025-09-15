-- ~/.config/awesome/custom/widgets/bar.lua
local gears = require("gears")
local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")

local Bar = {}

-- Создание кнопок для tasklist
local function create_tasklist_buttons()
    return gears.table.join(
        awful.button({ }, 1, function (c)
            if c == client.focus then
                c.minimized = true
            else
                c:emit_signal(
                    "request::activate",
                    "tasklist",
                    {raise = true}
                )
            end
        end),
        awful.button({ }, 3, function()
            awful.menu.client_list({ theme = { width = 250 } })
        end),
        awful.button({ }, 4, function ()
            awful.client.focus.byidx(1)
        end),
        awful.button({ }, 5, function ()
            awful.client.focus.byidx(-1)
        end)
    )
end

-- Создание wibox для экрана
function Bar.create_for_screen(s, mylauncher, mykeyboardlayout, mytextclock)
    -- Создаем promptbox
    s.mypromptbox = awful.widget.prompt()
    
    -- Создаем layoutbox
    local Layoutbox = require("custom.widgets.layoutbox")
    local layoutbox_widget = Layoutbox.new(s)
    s.mylayoutbox = layoutbox_widget.widget
    
    -- Создаем taglist
    local Taglist = require("custom.widgets.taglist")
    local taglist_widget = Taglist.new(s)
    s.mytaglist = taglist_widget.widget

    -- Получаем настройки
    local settings = require("custom.settings")
    
    -- Создаем wibox
    s.mywibox = wibox({
        screen = s,
        width = s.geometry.width - 20,
        height = settings.bar.height,
        x = 10,
        y = 10,
        bg = settings.bar.background,
        shape = gears.shape.rounded_rect,
        visible = true,
        type = "dock",
        opacity = 0.9
    })
    
    -- Устанавливаем struts для резервирования места
    s.mywibox:struts({
        top = settings.bar.height + 10
    })
    
    -- Добавляем прокрутку колеса мыши для переключения тегов
    s.mywibox:buttons(gears.table.join(
        awful.button({}, 4, function()
            awful.tag.viewprev(s)
        end),
        awful.button({}, 5, function()
            awful.tag.viewnext(s)
        end)
    ))
    
    -- >>> Пользовательские виджеты: начало
    local Volume = require("custom.widgets.volume")
    local PlayersCenter = require("custom.widgets.players_center")
    local SystemMonitor = require("custom.widgets.system_monitor")
    local Keyboard = require("custom.widgets.keyboard")
    local Date = require("custom.widgets.date")
    
    local volume_widget = Volume.new({ show_icon = true, width = 120 })
    local players_widget = PlayersCenter.new()
    local system_monitor_widget = SystemMonitor.new()
    local keyboard_widget = Keyboard.new()
    local date_widget = Date.new()
    -- >>> Пользовательские виджеты: конец

    s.mywibox:setup {
        {
            layout = wibox.layout.align.horizontal,
            {
                { -- Left widgets
                    layout = wibox.layout.fixed.horizontal,
                    s.mytaglist,
                    s.mypromptbox,
                },
                forced_width = 400,
                widget = wibox.container.constraint
            },
            wibox.container.place({
                layout = wibox.layout.fixed.horizontal,
                players_widget.widget,
                date_widget.widget,
            }),
            {
                {
                    { -- Right widgets
                        layout = wibox.layout.fixed.horizontal,
                        system_monitor_widget.widget,
                        keyboard_widget.widget,
                        volume_widget.widget,
                        s.mylayoutbox,
                    },
                    halign = "right",
                    widget = wibox.container.place
                },
                forced_width = 400,
                widget = wibox.container.constraint
            },
        },
        left = 8,
        right = 8,
        top = 4,
        bottom = 4,
        widget = wibox.container.margin
    }


end

return Bar    
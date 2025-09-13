-- ~/.config/awesome/custom/widgets/bar.lua
local gears = require("gears")
local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")

local Bar = {}

-- Создание кнопок для taglist
local function create_taglist_buttons()
    return gears.table.join(
        awful.button({ }, 1, function(t) t:view_only() end),
        awful.button({ modkey }, 1, function(t)
            if client.focus then
                client.focus:move_to_tag(t)
            end
        end),
        awful.button({ }, 3, awful.tag.viewtoggle),
        awful.button({ modkey }, 3, function(t)
            if client.focus then
                client.focus:toggle_tag(t)
            end
        end),
        awful.button({ }, 5, function(t) awful.tag.viewnext(t.screen) end),
        awful.button({ }, 4, function(t) awful.tag.viewprev(t.screen) end)
    )
end

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

-- Создание wibar для экрана
function Bar.create_for_screen(s, mylauncher, mykeyboardlayout, mytextclock)
    -- Создаем promptbox
    s.mypromptbox = awful.widget.prompt()
    
    -- Создаем layoutbox
    s.mylayoutbox = awful.widget.layoutbox(s)
    s.mylayoutbox:buttons(gears.table.join(
        awful.button({ }, 1, function () awful.layout.inc( 1) end),
        awful.button({ }, 3, function () awful.layout.inc(-1) end),
        awful.button({ }, 4, function () awful.layout.inc( 1) end),
        awful.button({ }, 5, function () awful.layout.inc(-1) end)
    ))
    
    -- Создаем taglist
    s.mytaglist = awful.widget.taglist {
        screen  = s,
        filter  = awful.widget.taglist.filter.all,
        buttons = create_taglist_buttons()
    }

    -- Создаем tasklist
    s.mytasklist = awful.widget.tasklist {
        screen  = s,
        filter  = awful.widget.tasklist.filter.currenttags,
        buttons = create_tasklist_buttons()
    }

    -- Создаем wibox
    s.mywibox = awful.wibar({ position = "top", screen = s })
    
    -- >>> Пользовательский код: начало
    -- Используем новый виджет Volume без иконки
    local Volume = require("custom.widgets.volume")
    local volume_widget = Volume.new({ show_icon = false, width = 120 })
    -- >>> Пользовательский код: конец

    -- Настраиваем виджеты в wibox
    s.mywibox:setup {
        layout = wibox.layout.align.horizontal,
        { -- Left widgets
            layout = wibox.layout.fixed.horizontal,
            mylauncher,
            s.mytaglist,
            s.mypromptbox,
        },
        s.mytasklist, -- Middle widget
        { -- Right widgets
            layout = wibox.layout.fixed.horizontal,
            mykeyboardlayout,
            wibox.widget.systray(),
            volume_widget.widget,
            mytextclock,
            s.mylayoutbox,
        },
    }
end

return Bar
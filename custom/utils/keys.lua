local awful = require("awful")
local modkey = "Mod4"

Keys = {
    awful.key({}, "Print", function()
        awful.spawn("flameshot gui")
    end, {description = "screenshot with Flameshot", group = "custom"}),
    awful.key({ modkey }, "q",
        function ()
            if client.focus then
                client.focus:kill()
            end
        end,
        {description = "close focused client", group = "client"}),
    awful.key({ modkey }, "f",
        function ()
            awful.spawn("nautilus")
        end,
        {description = "open Nautilus file manager", group = "launcher"}),
    -- Запуск Rofi при одиночном нажатии Mod4
	awful.key({ modkey }, "r",
    function ()
        awful.spawn("rofi -show drun")
    end,
    {description = "launch Rofi", group = "launcher"}),
    
    -- Переключение между окнами
   
    awful.key({ "Mod1" }, "Tab" ,
        function ()
            awful.client.focus.byidx(1)
end, {description = "focus previous client", group = "client"}),

}
return Keys


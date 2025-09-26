local awful = require("awful")

local Keys = {}

-- Ленивая загрузка settings для избежания циклической зависимости
local function get_settings()
    return require("custom.settings")
end

-- Генерируем клавиши из settings.keybindings
local settings = get_settings()
for _, binding in pairs(settings.keybindings) do
    if binding.key == "Print" then
        table.insert(Keys, awful.key({}, binding.key, function()
            awful.spawn(binding.command)
        end, {description = binding.description, group = binding.group}))
    elseif binding.key == "q" then
        table.insert(Keys, awful.key({binding.modkey}, binding.key, function()
            if client.focus then
                client.focus:kill()
            end
        end, {description = binding.description, group = binding.group}))
    elseif binding.key == "t" and binding.command then
        table.insert(Keys, awful.key({binding.modkey}, binding.key, function()
            awful.spawn(binding.command)
        end, {description = binding.description, group = binding.group}))
    elseif binding.key == "f" and binding.command then
        table.insert(Keys, awful.key({binding.modkey}, binding.key, function()
            awful.spawn(binding.command)
        end, {description = binding.description, group = binding.group}))
    elseif binding.key == "r" and binding.command then
        table.insert(Keys, awful.key({binding.modkey}, binding.key, function()
            awful.spawn(binding.command)
        end, {description = binding.description, group = binding.group}))
    elseif binding.key == "Tab" and binding.modkey == "Mod1" then
        table.insert(Keys, awful.key({binding.modkey}, binding.key, function()
            awful.client.focus.byidx(1)
        end, {description = binding.description, group = binding.group}))
    elseif binding.key == "w" and binding.modkey == "Mod4" then
        table.insert(Keys, awful.key({binding.modkey}, binding.key, function()
            local WallpaperSelector = require("custom.widgets.wallpaper_selector")
            WallpaperSelector.toggle()
        end, {description = binding.description, group = binding.group}))
    end
end

return Keys


-- ~/.config/awesome/custom/index.lua
local gears = require("gears")
local awful = require("awful")

-- Загружаем тему в самом начале
local WalColors = require("custom.utils.wal_colors")
WalColors.reload_settings_colors()

local M = {}

local function loadModule(moduleName)
	local ok_keys, loaded_module = pcall(require, moduleName)

	if ok_keys then
		M[moduleName] = loaded_module  -- возвращаем массив ключей
	else
        error("Не удалось загрузить модуль: " .. moduleName .. "\nПричина: " .. tostring(loaded_module))
	end
end
-- подключаем подмодули

local keys = "custom.utils.keys"
local autostart = "custom.utils.autostart"
local windows = "custom.utils.windows"
local wallpaper = "custom.utils.wallpaper"
local bar = "custom.widgets.bar"
local window_rules = "custom.utils.window_rules"

loadModule(keys)
loadModule(autostart)
loadModule(windows)
loadModule(wallpaper)
loadModule(bar)
loadModule(window_rules)

-- Прямое подключение менеджера уведомлений
local notification_manager = require("custom.utils.notification_manager")
local DesktopNotifications = require("custom.widgets.desktop_notifications")
local WeatherAPI = require("custom.utils.weather_api")

function M.apply_keys(globalkeys)
    return gears.table.join(globalkeys, table.unpack(M[keys]))
end

function M.autostart(globalkeys)
    M[autostart].run()
end

function M.setWallpaper()
    M[wallpaper].set()
end

function M.windowsSettings(client)
    M[windows].newWindowToTheEndOfWindowsList(client)
    M[windows].setupGaps()
    M[window_rules].setup()
    DesktopNotifications.setup()
    WeatherAPI.setup()
    
    -- Инициализация виджета выбора обоев
    local WallpaperSelector = require("custom.widgets.wallpaper_selector")
    WallpaperSelector.new()
    
    -- Генерируем цветовые файлы
    local ColorGenerators = require("custom.utils.color_generators")
    ColorGenerators.generate_all()
end

function M.createBar()
    return M[bar]
end

function M.getNotificationManager()
    return notification_manager
end

return M


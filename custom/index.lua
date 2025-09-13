-- ~/.config/awesome/custom/index.lua
local gears = require("gears")
local awful = require("awful")

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
local bar = "custom.widgets.bar"

loadModule(keys)
loadModule(autostart)
loadModule(windows)
loadModule(bar)

function M.apply_keys(globalkeys)
    return gears.table.join(globalkeys, table.unpack(M[keys]))
end

function M.autostart(globalkeys)
    M[autostart].run()
end

function M.windowsSettings(client)
    M[windows].newWindowToTheEndOfWindowsList(client)
    M[windows].setupGaps()
end

function M.createBar()
    return M[bar]
end

return M


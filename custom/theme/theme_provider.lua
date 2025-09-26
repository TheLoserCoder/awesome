-- ~/.config/awesome/custom/theme/theme_provider.lua
local rubato = require("custom.utils.rubato")
local beautiful = require("beautiful")
local DebugLogger = require("custom.utils.debug_logger")


local ThemeProvider = {}
ThemeProvider.__index = ThemeProvider

local _instance = nil

function ThemeProvider.new(opts)
    if _instance then return _instance end
    opts = opts or {}
    local self = setmetatable({}, ThemeProvider)
    
    self.duration = opts.duration or 1.0
    self.easing = opts.easing or rubato.quadratic
    
    self.prev_theme = {}
    self.next_theme = {}
    self.subscribers = {}
    
    -- Слушаем события изменения темы
    awesome.connect_signal("theme::changed", function(new_theme, old_theme)
        DebugLogger.log("ThemeProvider: Получен сигнал theme::changed")
        self:_start_animation(new_theme, old_theme)
    end)
    
    _instance = self
    return self
end

function ThemeProvider:subscribe(fn)
    table.insert(self.subscribers, fn)
    return fn
end

function ThemeProvider:unsubscribe(fn)
    for i, v in ipairs(self.subscribers) do
        if v == fn then 
            table.remove(self.subscribers, i)
            break 
        end
    end
end

function ThemeProvider:_create_animation_callback(prev_theme, next_theme)
    return function(t)

        for _, fn in ipairs(self.subscribers) do
            fn(t, prev_theme, next_theme)
        end
    end
end

function ThemeProvider:_start_animation(theme_table, old_theme_from_signal)
    DebugLogger.log("ThemeProvider: Начинаем анимацию смены темы")
    
    local function shallow_copy(t)
        local r = {}
        if not t then return r end
        for k,v in pairs(t) do r[k] = v end
        return r
    end
    
    -- Проверяем является ли это первой сменой темы
    local is_first_theme = next(self.next_theme) == nil
    DebugLogger.log("ThemeProvider: is_first_theme = " .. tostring(is_first_theme))
    
    local prev_theme
    
    if is_first_theme and old_theme_from_signal then
        -- Первая смена - используем сохраненные старые цвета
        prev_theme = shallow_copy(old_theme_from_signal)
        DebugLogger.log("ThemeProvider: prev_theme (из сигнала): text=" .. tostring(prev_theme.text) .. ", accent=" .. tostring(prev_theme.accent))
    elseif is_first_theme then
        -- Fallback для первой смены без old_theme
        prev_theme = {
            text = beautiful.text,
            text_secondary = beautiful.text_secondary,
            text_muted = beautiful.text_muted,
            background = beautiful.background,
            surface = beautiful.surface,
            accent = beautiful.accent
        }
        DebugLogger.log("ThemeProvider: prev_theme (fallback из beautiful): text=" .. tostring(prev_theme.text) .. ", accent=" .. tostring(prev_theme.accent))
    else
        prev_theme = shallow_copy(self.next_theme)
        DebugLogger.log("ThemeProvider: prev_theme (из next_theme): text=" .. tostring(prev_theme.text) .. ", accent=" .. tostring(prev_theme.accent))
    end
    
    local next_theme = shallow_copy(theme_table)
    DebugLogger.log("ThemeProvider: next_theme: text=" .. tostring(next_theme.text) .. ", accent=" .. tostring(next_theme.accent))
    
    self.prev_theme = prev_theme
    self.next_theme = next_theme
    
    -- Создаем новую анимацию каждый раз
    DebugLogger.log("ThemeProvider: Создаем анимацию, подписчиков: " .. #self.subscribers)
    local anim = rubato.timed {
        duration = self.duration,
        easing = self.easing,
        subscribed = function(t)
            if t == 0 then
                DebugLogger.log("ThemeProvider: Анимация началась (t=0)")
            elseif t >= 1 then
                DebugLogger.log("ThemeProvider: Анимация завершена (t=1)")
            end
            -- Вызываем callback'ы для виджетов
            for _, fn in ipairs(self.subscribers) do
                fn(t, prev_theme, next_theme)
            end
        end
    }
    
    anim.pos = 0
    anim.target = 1
    DebugLogger.log("ThemeProvider: Анимация запущена")
end

function ThemeProvider.get()
    return ThemeProvider.new()
end

return ThemeProvider
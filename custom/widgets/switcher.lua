-- ~/.config/awesome/custom/widgets/switcher.lua
local wibox = require("wibox")
local gears = require("gears")
local rubato = require("custom.utils.rubato")
local settings = require("custom.settings")

local Switcher = {}
Switcher.__index = Switcher

function Switcher.new(config)
    config = config or {}
    local self = setmetatable({}, Switcher)
    
    -- Параметры
    self.width = 40
    self.height = 20
    self.knob_size = self.height - 6
    local state = config.initial_state or false
    
    self.state = state
    self.on_change = config.on_change or function() end
    
    -- Функция для получения актуальных цветов
    local function get_colors()
        return settings.colors
    end
    
    local colors = get_colors()
    self.on_color = colors.accent
    self.off_color = colors.surface
    
    -- Фоновая дорожка
    local track = wibox.widget {
        shape = function(cr, w, h) gears.shape.rounded_rect(cr, w, h, h/2) end,
        forced_height = self.height,
        forced_width = self.width,
        widget = wibox.container.background,
        bg = state and on_color or off_color,
    }
    
    -- Кружок
    local knob = wibox.widget {
        widget = wibox.container.background,
        shape = gears.shape.circle,
        forced_width = self.knob_size,
        forced_height = self.knob_size,
        bg = state and colors.surface or colors.text,
    }
    
    self.knob = knob
    
    -- Контейнер с отступами для позиционирования
    local knob_margin = wibox.container.margin()
    knob_margin.left = state and (self.width - self.knob_size - 3) or 3
    knob_margin.widget = knob
    
    -- Оверлей
    local overlay = wibox.widget {
        track,
        {
            knob_margin,
            layout = wibox.layout.fixed.horizontal
        },
        layout = wibox.layout.stack
    }
    
    local switch_container = wibox.widget {
        overlay,
        widget = wibox.container.margin,
        margins = 0
    }
    
    self.track = track
    self.knob_margin = knob_margin
    self.switch_container = switch_container
    
    -- Label
    local label_widget = config.label_widget
    if not label_widget and config.label then
        local Text = require("custom.widgets.base_widgets.text")
        label_widget = Text.new({
            text = config.label,
            font = config.label_font or settings.fonts.main .. " 10",
            color = config.label_color
        })
    end
    
    -- Основной виджет без Container для прозрачности
    local content = label_widget and wibox.widget {
        label_widget,
        switch_container,
        spacing = 8,
        layout = wibox.layout.fixed.horizontal
    } or switch_container
    
    self.widget = wibox.widget {
        content,
        forced_height = self.height,
        widget = wibox.container.constraint
    }
    
    -- Анимация позиции
    self.anim = rubato.timed {
        duration = 0.18,
        pos = knob_margin.left,
        easing = rubato.quadratic,
        subscribed = function(x)
            knob_margin.left = math.floor(x)
        end
    }
    
    -- Анимация цвета фона
    local ColorAnimator = require("custom.utils.color_animator")
    self.color_anim = ColorAnimator.new({
        duration = 0.18,
        easing = rubato.quadratic,
        from_color = state and self.on_color or self.off_color,
        callback = function(color)
            track.bg = color
        end
    })
    
    -- Анимация цвета кружка
    self.knob_color_anim = ColorAnimator.new({
        duration = 0.18,
        easing = rubato.quadratic,
        from_color = state and colors.surface or colors.text,
        callback = function(color)
            knob.bg = color
        end
    })
    

    

    
    -- Обработчик клика
    self.widget:connect_signal("button::press", function()
        self:toggle()
    end)
    
    -- Подписываемся на изменения темы
    local ThemeProvider = require("custom.theme.theme_provider")
    ThemeProvider.get():subscribe(function()
        local new_colors = settings.colors
        self.on_color = new_colors.accent
        self.off_color = new_colors.surface
        
        -- Обновляем цвета без анимации
        if self.state then
            track.bg = self.on_color
            knob.bg = new_colors.surface
        else
            track.bg = self.off_color
            knob.bg = new_colors.text
        end
    end)
    
    return self
end

function Switcher:toggle()
    self.state = not self.state
    local colors = settings.colors
    
    -- Обновляем цвета из провайдера
    self.on_color = colors.accent
    self.off_color = colors.surface
    
    if self.state then
        self.color_anim:animate_to(self.on_color)
        self.knob_color_anim:animate_to(colors.surface)
        self.anim.target = self.width - self.knob_size - 3
    else
        self.color_anim:animate_to(self.off_color)
        self.knob_color_anim:animate_to(colors.text)
        self.anim.target = 3
    end
    
    self.on_change(self.state)
end

function Switcher:set_state(state)
    if self.state == state then return end
    self:toggle()
end

function Switcher:get_state()
    return self.state
end

return Switcher
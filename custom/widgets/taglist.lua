-- ~/.config/awesome/custom/widgets/taglist.lua
local gears = require("gears")
local awful = require("awful")
local wibox = require("wibox")

local Taglist = {}
Taglist.__index = Taglist

local Container = require("custom.widgets.base_widgets.container")
local Text = require("custom.widgets.base_widgets.text")
local Button2 = require("custom.widgets.button_2")
local Animate = require("custom.utils.animate")
local settings = require("custom.settings")

 
function Taglist.new(screen, config)
    local self = setmetatable({}, Taglist)
    config = config or {}
    

    self.screen = screen
    self.config = config
    
    -- Параметры
    local spacing = config.spacing or 2
    local indicator_size = config.indicator_size or 16
    local max_button_width = config.max_button_width or 100
   
    local tag_colors = config.colors or {
        background = settings.colors.surface,
        indicator = settings.colors.accent .. "40",
        active_tag = settings.colors.surface,
        normal_tag = settings.colors.text,
        hover_button = settings.colors.surface .. "40"
    }
    local background = tag_colors.background
    local tags = config.tags or {}
    
    -- Создаем индикатор (прямоугольник)
    self.indicator = wibox.widget {
        widget = wibox.container.background,
        shape = function(cr, width, height)
            gears.shape.rounded_rect(cr, width, height, 12)
        end,
        forced_width = indicator_size,
        forced_height = 18,
        bg = tag_colors.indicator
    }
    
    -- Margin для позиционирования индикатора
    self.indicator_margin = wibox.widget {
        self.indicator,
        left = 0,
      
        widget = wibox.container.margin
    }
    
    -- Place контейнер с выравниванием по левому краю
    self.indicator_container = wibox.widget {
        self.indicator_margin,
        halign = "left",
        valign = "center",
        widget = wibox.container.place
    }
    
    -- Анимации через класс Animate
    self.mover = Animate.position {
        duration = 0.22,
        initial_pos = 0,
        subscribed = function(pos)
            if pos and self.indicator_margin then
                self.indicator_margin.left = math.floor(pos + 0.5)
            end
        end
    }
    
    -- Создаем sizer без начального размера - установим после создания кнопок
    self.sizer = nil

    
    -- Создаем кнопки
    self.buttons = {}
    local buttons_layout = wibox.widget {
        layout = wibox.layout.fixed.horizontal,
        spacing = spacing
    }
    
    for i, tag_config in ipairs(tags) do
        local tag = screen.tags[i]
        if tag then
            local text_args = {
                text = tag_config.name,
                theme_color = "text",
                font = "Ubuntu Bold 10"
            }
            
            -- Если есть явный цвет, устанавливаем его и отключаем тему
            if tag_config.color then
                text_args.color = tag_config.color
                text_args.themed = false
            end
            
            local text_widget = wibox.widget {
                Text.new(text_args),
                align = "center",
                valign = "center",
                widget = wibox.container.place
            }
            
            -- Вычисляем ширину кнопки на основе текста
            local text_width = 10 -- базовая ширина
            local button_width = math.min(text_width + 16, max_button_width)
            
            local button_bg = Button2.new({
                content = text_widget,
                width = button_width,
                height = 18,
                bg_default = "#00000000", -- прозрачный фон
                bg_hover = tag_colors.hover_button,
                margins = 2,
                on_click = function()
                    tag:view_only()
                end
            })
            
            self.buttons[i] = {
                widget = button_bg.widget,
                text_widget = text_widget,
                tag = tag,
                button2 = button_bg
            }
            
            buttons_layout:add(button_bg.widget)
            
            -- Обновляем стиль при изменении тега
            tag:connect_signal("property::selected", function()
                if tag.selected then
                    self:_move_indicator_to(i)
                end
            end)
            
            tag:connect_signal("property::urgent", function()
                self:_update_button_style(i)
            end)
        end
    end
    
    -- Создаем stack: сначала контейнер индикатора (на всю ширину), потом кнопки
    local taglist_content = wibox.widget {
        self.indicator_container,
        buttons_layout,
        layout = wibox.layout.stack
    }
    
    -- Добавляем фон с ограничением высоты
    local background_container = Container.new({
        theme_color = "surface",
        content = taglist_content,
        margins = 4,
        shape = function(cr, width, height)
            gears.shape.rounded_rect(cr, width, height, 12)
        end
    })
    
    self.widget = wibox.widget {
        background_container,
        forced_height = 28,
        valign = "center",
        widget = wibox.container.place
    }
    
    -- Создаем sizer с правильным начальным размером
    local initial_width = indicator_size
    for i = 1, 9 do
        local button = self.buttons[i]
        if button and button.tag.selected then
            initial_width = button.button2.width or indicator_size
            break
        end
    end
    
    self.sizer = Animate.position {
        duration = 0.15,
        initial_pos = initial_width,
        subscribed = function(pos)
            if pos and self.indicator then
                self.indicator.forced_width = math.floor(pos + 0.5)
            end
        end
    }
    
    -- Инициализация
    self:_update_all_buttons()
    self:_set_initial_indicator_position()
    
    return self
end

function Taglist:_x_for_index(idx)
    local spacing = self.config.spacing or 2
    
    -- Вычисляем позицию левого края кнопки
    local left = 0
    for i = 1, idx - 1 do
        if self.buttons[i] then
            local button_width = self.buttons[i].button2.width or 24
            left = left + button_width + spacing
        end
    end
    
    return left
end

function Taglist:_move_indicator_to(index)
    local target_x = self:_x_for_index(index)
    local target_width = self.buttons[index] and self.buttons[index].button2.width or (self.config.indicator_size or 16)
    
    if self.mover then
        self.mover.target = target_x
    end
    
    -- Анимация размера
    if self.sizer then
        self.sizer.target = target_width
    end
end

function Taglist:_set_initial_indicator_position()
    for i = 1, 9 do
        local button = self.buttons[i]
        if button and button.tag.selected then
            local pos = self:_x_for_index(i)
            local width = button.button2.width or (self.config.indicator_size or 16)
            
            -- Применяем сразу без анимации
            if self.mover then
                self.mover.pos = pos
                if self.indicator_margin then
                    self.indicator_margin.left = pos
                end
            end
            
            if self.sizer then
                self.sizer.pos = width
                if self.indicator then
                    self.indicator.forced_width = width
                end
            end
            break
        end
    end
end

function Taglist:_update_button_style(index)
    local button = self.buttons[index]
    if not button then return end
    
    button.button2:set_bg("#00000000")
end

function Taglist:_update_all_buttons()
    for i = 1, 9 do
        self:_update_button_style(i)
    end
end

function Taglist:_recalculate_sizes()
    -- Обновляем позицию индикатора для выбранного тега
    for i = 1, 9 do
        local button = self.buttons[i]
        if button and button.tag.selected then
            local pos = self:_x_for_index(i)
            
            -- Обновляем позицию
            if self.mover.pos ~= pos then
                self.mover.pos = pos
                self.indicator_margin.left = pos
            end
            break
        end
    end
end


return Taglist
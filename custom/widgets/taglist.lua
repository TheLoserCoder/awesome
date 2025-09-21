-- ~/.config/awesome/custom/widgets/taglist.lua
local gears = require("gears")
local awful = require("awful")
local wibox = require("wibox")

local Taglist = {}
Taglist.__index = Taglist

local Provider = require("custom.widgets.provider")
local Animate = require("custom.utils.animate")
local settings = require("custom.settings")
local debug_logger = require("custom.utils.debug_logger")
 
function Taglist.new(screen, config)
    local self = setmetatable({}, Taglist)
    config = config or {}
    
    local colors = Provider.get_colors()
    self.screen = screen
    self.config = config
    
    -- Параметры
    local spacing = config.spacing or 4
    local indicator_size = config.indicator_size or 16
    local max_button_width = config.max_button_width or 100
   
    local tag_colors = config.colors or {
        background = settings.colors.surface .. "80",
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
            local text_widget = wibox.widget {
                text = tag_config.name,
                align = "center",
                valign = "center",
                font = "Ubuntu Bold 10",
                widget = wibox.widget.textbox
            }
            
            -- Вычисляем ширину кнопки на основе текста
            local text_width = text_widget:get_preferred_size() or 20
            local button_width = math.min(text_width + 16, max_button_width)
            
            local button_bg = wibox.widget {
                {
                    text_widget,
                    margins = 2,
                    widget = wibox.container.margin
                },
                forced_width = button_width,
                forced_height = 18,
                shape = gears.shape.rounded_rect,
                bg = "#00000000", -- прозрачный фон
                widget = wibox.container.background
            }
            
            -- Обработка наведения
            button_bg:connect_signal("mouse::enter", function()
                if not tag.selected then
                    button_bg.bg = tag_colors.hover_button
                end
            end)
            
            button_bg:connect_signal("mouse::leave", function()
                if not tag.selected then
                    button_bg.bg = "#00000000"
                end
            end)
            
            -- Обработка клика
            button_bg:buttons(gears.table.join(
                awful.button({}, 1, function()
                    tag:view_only()
                end)
            ))
            
            self.buttons[i] = {
                widget = button_bg,
                text_widget = text_widget,
                tag = tag
            }
            
            buttons_layout:add(button_bg)
            
            -- Обновляем стиль при изменении тега
            tag:connect_signal("property::selected", function()

                if tag.selected then
                    self:_move_indicator_to(i)
                else
                    self:_update_all_buttons()
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
    self.widget = wibox.widget {
        {
            {
                taglist_content,
                margins = 4,
                widget = wibox.container.margin
            },
            bg = tag_colors.background,
            shape = function(cr, width, height)
                gears.shape.rounded_rect(cr, width, height, 12)
            end,
            widget = wibox.container.background
        },
        forced_height = 28,
        valign = "center",
        widget = wibox.container.place
    }
    
    -- Создаем sizer с правильным начальным размером
    local initial_width = indicator_size
    for i = 1, 9 do
        local button = self.buttons[i]
        if button and button.tag.selected then
            initial_width = button.widget.forced_width or indicator_size
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
    local spacing = self.config.spacing or 4
    
    -- Вычисляем позицию левого края кнопки
    local left = 0
    for i = 1, idx - 1 do
        if self.buttons[i] then
            left = left + (self.buttons[i].widget.forced_width or 24) + spacing
        end
    end
    
    return left
end

function Taglist:_move_indicator_to(index)

    local target_x = self:_x_for_index(index)
    local target_width = self.buttons[index] and self.buttons[index].widget.forced_width or (self.config.indicator_size or 16)
    
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
            local width = button.widget.forced_width or (self.config.indicator_size or 16)
            
            -- Применяем сразу без анимации
            self.mover.pos = pos
            self.sizer.pos = width
            self.indicator_margin.left = pos
            self.indicator.forced_width = width
            break
        end
    end
end

function Taglist:_update_button_style(index)
    local button = self.buttons[index]
    if not button then return end
    
    local tag = button.tag
    local tag_config = self.config.tags[index]
    local tag_name = tag_config and tag_config.name or tostring(index)
    local tag_color = tag_config and tag_config.color or (tag.selected and self.config.colors.active_tag or self.config.colors.normal_tag)
    
    button.widget.bg = "#00000000"
    button.text_widget.markup = '<span color="' .. tag_color .. '">' .. tag_name .. '</span>'
end

function Taglist:_update_all_buttons()
    for i = 1, 9 do
        self:_update_button_style(i)
    end
end

function Taglist:_recalculate_sizes()
    -- Сохраняем текущие размеры кнопок
    local current_widths = {}
    for i, button in pairs(self.buttons) do
        if button then
            current_widths[i] = button.widget.forced_width
        end
    end
    
    -- Пересчитываем размеры кнопок только если они еще не установлены
    for i, button in pairs(self.buttons) do
        if button and button.text_widget and not current_widths[i] then
            local text_width = button.text_widget:get_preferred_size() or 20
            local button_width = math.min(text_width + 16, self.config.max_button_width or 100)
            button.widget.forced_width = button_width
        end
    end
    
    -- Обновляем только позицию индикатора
    for i = 1, 9 do
        local button = self.buttons[i]
        if button and button.tag.selected then
            local pos = self:_x_for_index(i)
            
            -- Обновляем только позицию
            if self.mover.pos ~= pos then
                self.mover.pos = pos
                self.indicator_margin.left = pos
            end
            break
        end
    end
end

return Taglist
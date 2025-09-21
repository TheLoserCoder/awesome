-- ~/.config/awesome/custom/widgets/custom_scroll.lua
local wibox = require("wibox")
local rubato = require("custom.utils.rubato")

local CustomScroll = {}
CustomScroll.__index = CustomScroll

function CustomScroll.new(opts)
    opts = opts or {}
    local self = setmetatable({}, CustomScroll)
    
    -- Параметры
    self.viewport_height = opts.height or 200
    self.inner_height = opts.inner_height or opts.height or 200
    self.scroll_step = opts.step or 40
    self.scroll_offset_y = 0
    
    -- Внутренний контейнер
    self.inner_container = wibox.widget {
        {
            text = "Пустой контент",
            widget = wibox.widget.textbox,
        },
        forced_height = self.inner_height,
        widget = wibox.container.constraint
    }
    
    -- Margin контейнер для смещения
    self.margin_container = wibox.widget {
        self.inner_container,
        top = 0,
        widget = wibox.container.margin
    }
    
    -- Viewport с обрезкой
    self.viewport = wibox.widget {
        self.margin_container,
        forced_height = self.viewport_height,
        clip = true,
        widget = wibox.container.background
    }
    
    -- Анимация прокрутки (создаем после margin_container)
    self.scroll_animation = rubato.timed {
        duration = 0.2,
        intro = 0.05,
        outro = 0.1,
        easing = rubato.linear,
        subscribed = function(pos)
            self.margin_container.top = -pos
            self.viewport:emit_signal("widget::layout_changed")
        end
    }
    
    -- Обработка событий мыши
    self.viewport:connect_signal("button::press", function(_, lx, ly, button, mods, find_widgets_result)
        if button == 4 then -- wheel up
            self:scroll_by(-self.scroll_step)
        elseif button == 5 then -- wheel down
            self:scroll_by(self.scroll_step)
        end
    end)
    
    return self
end

function CustomScroll:set_content(content_widget)
    if not content_widget then return end
    
    self.inner_container = wibox.widget {
        content_widget,
        forced_height = self.inner_height,
        widget = wibox.container.constraint
    }
    
    self.margin_container:set_widget(self.inner_container)
end

function CustomScroll:scroll_by(delta)
    -- Проверяем, нужна ли прокрутка
    if self.inner_height <= self.viewport_height then
        return
    end
    
    -- Обновляем смещение
    self.scroll_offset_y = self.scroll_offset_y + delta
    
    -- Ограничиваем прокрутку
    local max_offset = self.inner_height - self.viewport_height
    if self.scroll_offset_y < 0 then 
        self.scroll_offset_y = 0 
    elseif self.scroll_offset_y > max_offset then 
        self.scroll_offset_y = max_offset 
    end
    
    -- Анимируем к новой позиции
    self.scroll_animation.target = self.scroll_offset_y
end

function CustomScroll:scroll_to(position)
    self.scroll_offset_y = position or 0
    self.scroll_animation.target = self.scroll_offset_y
end

function CustomScroll:reset()
    self.scroll_offset_y = 0
    self.scroll_animation.target = 0
end

function CustomScroll:scroll_to_element(element_index, element_height, element_spacing)
    if not element_index or element_index < 1 then return end
    
    -- Вычисляем позицию элемента
    local element_top = (element_index - 1) * (element_height + element_spacing)
    local element_bottom = element_top + element_height
    
    -- Текущие границы видимости
    local viewport_top = self.scroll_offset_y
    local viewport_bottom = self.scroll_offset_y + self.viewport_height
    
    -- Проверяем, нужна ли прокрутка
    if element_top < viewport_top then
        -- Элемент выше видимой области - прокручиваем вверх
        self:scroll_to(element_top)
    elseif element_bottom > viewport_bottom then
        -- Элемент ниже видимой области - прокручиваем вниз
        self:scroll_to(element_bottom - self.viewport_height)
    end
end

function CustomScroll:update_inner_height(new_height)
    self.inner_height = new_height
    self.inner_container.forced_height = new_height
    
    -- Проверяем, не вышли ли за границы после изменения высоты
    local max_offset = math.max(0, self.inner_height - self.viewport_height)
    if self.scroll_offset_y > max_offset then
        self.scroll_offset_y = max_offset
        self.margin_container.top = -self.scroll_offset_y
        self.viewport:emit_signal("widget::layout_changed")
    end
end

function CustomScroll:get_widget()
    return self.viewport
end

return CustomScroll
-- ~/.config/awesome/custom/widgets/image.lua
local wibox = require("wibox")
local gears = require("gears")

local Image = {}
Image.__index = Image

local ImageLoader = require("custom.utils.image_loader")
local Text = require("custom.widgets.base_widgets.text")

function Image.new(config)
    local self = setmetatable({}, Image)
    
    config = config or {}
    self.fallback_icon = config.fallback_icon or ""
    self.width = config.width or 60
    self.height = config.height or 60
    self.shape = config.shape
    self.current_source = nil -- для предотвращения гонок
    
    self:_create_widgets()
    
    return self
end

function Image:_create_widgets()
    -- Виджет изображения
    self.image_widget = wibox.widget {
        {
            resize = true,
            widget = wibox.widget.imagebox
        },
        valign = "center",
        halign = "center",
        widget = wibox.container.place
    }
    
    -- Фолбек иконка
    self.fallback_widget = wibox.widget {
        {
            Text.new({
                text = self.fallback_icon,
                font = "Font Awesome 6 Free 32",
                theme_color = "text_secondary"
            }),
            valign = "center",
            halign = "center",
            widget = wibox.container.place
        },
        widget = wibox.container.background
    }
    
    -- Стек виджетов
    self.stack = wibox.widget {
        self.fallback_widget,
        self.image_widget,
        top_only = true,
        widget = wibox.layout.stack
    }
    
    self.widget = wibox.widget {
        {
            self.stack,
            forced_width = self.width,
            forced_height = self.height,
            widget = wibox.container.constraint
        },
        shape = self.shape,
        widget = wibox.container.background
    }
    
    -- Показываем фолбек по умолчанию
    self.showing_image = false
end

function Image:set_source(source)
    self.current_source = source

    if not source or source == "" then
        self:_show_fallback()
        return
    end

    if ImageLoader.is_url(source) then
        ImageLoader.load_from_url(source, function(surface)
            if self.current_source ~= source then
                return
            end

            if surface then
                self.image_widget:get_children()[1].image = surface
                self:_show_image()
            else
                self:_show_fallback()
            end
        end)
    elseif ImageLoader.is_file_url(source) then
        local file_path = ImageLoader.file_url_to_path(source)
        self.image_widget:get_children()[1].image = file_path
        self:_show_image()
    elseif ImageLoader.is_base64_data(source) then
        ImageLoader.load_from_base64(source, function(surface)
            if self.current_source ~= source then
                return
            end

            if surface then
                self.image_widget:get_children()[1].image = surface
                self:_show_image()
            else
                self:_show_fallback()
            end
        end)
    else
        -- локальный файл
        self.image_widget:get_children()[1].image = source
        self:_show_image()
    end
end

function Image:_show_image()
    self.stack:set(1, self.image_widget)
    self.showing_image = true
end

function Image:_show_fallback()
    self.stack:set(1, self.fallback_widget)
    self.showing_image = false
end

return Image

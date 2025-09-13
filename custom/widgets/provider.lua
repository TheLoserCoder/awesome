-- ~/.config/awesome/custom/widgets/provider.lua
local gears = require("gears")
local wibox = require("wibox")
local beautiful = require("beautiful")

local Provider = {}

-- Получаем настройки
local settings = require("custom.settings")

-- Создание базового контейнера с настройками из settings
function Provider.create_container(config)
    config = config or {}
    
    local container_config = {
        bg = config.bg or settings.colors.background,
        fg = config.fg or settings.colors.foreground,
        shape = config.shape or gears.shape.rounded_rect,
        border_width = config.border_width or settings.dimensions.border_width,
        border_color = config.border_color or settings.colors.surface,
        margins = config.margins or settings.dimensions.margin,
        paddings = config.paddings or settings.dimensions.padding,
        widget = wibox.container.background
    }
    
    return wibox.widget(container_config)
end

-- Создание текстового виджета с настройками из settings
function Provider.create_textbox(config)
    config = config or {}
    
    local textbox_config = {
        text = config.text or "",
        font = config.font or settings.fonts.main,
        align = config.align or "center",
        valign = config.valign or "center",
        widget = wibox.widget.textbox
    }
    
    return wibox.widget(textbox_config)
end

-- Создание макета с настройками из settings
function Provider.create_layout(layout_type, config)
    config = config or {}
    layout_type = layout_type or "horizontal"
    
    local layout_config = {
        spacing = config.spacing or settings.dimensions.spacing,
        layout = layout_type == "horizontal" and wibox.layout.fixed.horizontal or wibox.layout.fixed.vertical
    }
    
    return wibox.widget(layout_config)
end

-- Применение темы к виджету
function Provider.apply_theme(widget, theme_config)
    theme_config = theme_config or {}
    
    if widget.set_bg and theme_config.bg then
        widget:set_bg(theme_config.bg)
    end
    
    if widget.set_fg and theme_config.fg then
        widget:set_fg(theme_config.fg)
    end
    
    if widget.set_font and theme_config.font then
        widget:set_font(theme_config.font)
    end
    
    return widget
end

-- Создание стилизованного виджета с полными настройками
function Provider.create_styled_widget(widget_content, style_config)
    style_config = style_config or {}
    
    local container = Provider.create_container({
        bg = style_config.bg or settings.colors.surface,
        fg = style_config.fg or settings.colors.text,
        border_color = style_config.border_color or settings.colors.primary,
        margins = style_config.margins,
        paddings = style_config.paddings
    })
    
    container:setup {
        widget_content,
        margins = style_config.margins or settings.dimensions.margin,
        widget = wibox.container.margin
    }
    
    return container
end

-- Получение настроек
function Provider.get_settings()
    return settings
end

-- Получение цветов
function Provider.get_colors()
    return settings.colors
end

-- Получение шрифтов
function Provider.get_fonts()
    return settings.fonts
end

-- Получение размеров
function Provider.get_dimensions()
    return settings.dimensions
end

return Provider
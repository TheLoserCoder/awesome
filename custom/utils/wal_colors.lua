-- ~/.config/awesome/custom/utils/wal_colors.lua
local json = require("dkjson")

local beautiful = require("beautiful")
local WalColors = {}

function WalColors.reload_settings_colors()


    
    local colors = WalColors.load_colors_from_file()
    if colors then

        
        -- Обновляем settings
        local settings = require("custom.settings")
        settings.colors = colors
        
        -- Создаем объект темы
        local theme_data = {
            bg_normal = colors.background,
            fg_normal = colors.text,
            background = colors.background,
            surface = colors.surface,
            surface_alt = colors.surface_alt,
            text = colors.text,
            text_secondary = colors.text_secondary,
            text_muted = colors.text_muted,
            accent = colors.accent,
            transparent = colors.transparent,
            wallpaper = colors.wallpaper,
            useless_gap = settings.dimensions.useless_gap,
            border_normal = colors.transparent,
            border_focus = colors.accent,
            -- Иконки раскладок
            layout_tile = "/usr/share/awesome/themes/default/layouts/tilew.png",
            layout_tileleft = "/usr/share/awesome/themes/default/layouts/tileleftw.png",
            layout_tilebottom = "/usr/share/awesome/themes/default/layouts/tilebottomw.png",
            layout_tiletop = "/usr/share/awesome/themes/default/layouts/tiletopw.png",
            layout_fairv = "/usr/share/awesome/themes/default/layouts/fairvw.png",
            layout_fairh = "/usr/share/awesome/themes/default/layouts/fairhw.png",
            layout_spiral = "/usr/share/awesome/themes/default/layouts/spiralw.png",
            layout_dwindle = "/usr/share/awesome/themes/default/layouts/dwindlew.png",
            layout_max = "/usr/share/awesome/themes/default/layouts/maxw.png",
            layout_fullscreen = "/usr/share/awesome/themes/default/layouts/fullscreenw.png",
            layout_magnifier = "/usr/share/awesome/themes/default/layouts/magnifierw.png",
            layout_floating = "/usr/share/awesome/themes/default/layouts/floatingw.png"
        }
        
        -- Сохраняем старые цвета перед обновлением
        local old_theme = {
            text = beautiful.text,
            text_secondary = beautiful.text_secondary,
            text_muted = beautiful.text_muted,
            background = beautiful.background,
            surface = beautiful.surface,
            accent = beautiful.accent,
            transparent = beautiful.transparent or "#00000000",
            border_normal = beautiful.border_normal,
            border_focus = beautiful.border_focus
        }
        
        -- Сначала инициализируем тему
        beautiful.init(theme_data)
        
        -- Перекрашиваем иконки макета
        beautiful.theme_assets.recolor_layout(beautiful, colors.text)
        
        -- Отправляем сигнал о смене темы с сохраненными старыми цветами
        awesome.emit_signal("theme::changed", theme_data, old_theme)
        
        -- Генерируем цветовые файлы
        local ColorGenerators = require("custom.utils.color_generators")
        ColorGenerators.generate_all()
        
        return true
    end


    return false
end



function WalColors.load_colors_from_file()
    local wal_colors_path = os.getenv("HOME") .. "/.cache/wal/colors.json"
    
    local file = io.open(wal_colors_path, "r")
    if not file then

        return nil
    end
    
    local content = file:read("*all")
    file:close()
    
    local colors_data, pos, err = json.decode(content)
    if not colors_data or not colors_data.colors then

        return nil
    end
    
    local colors = colors_data.colors

    
    local result = {
        background = colors.color0 and (colors.color0 .. "70") or "#1E1E2E70",
        surface = colors.color1 and (colors.color1 .. "70") or "#2A2A3C70",
        surface_alt = colors.color1 or "#2A2A3C", -- Непрозрачный surface для hover
        text = colors.color15 or "#ECEFF4",
        text_secondary = colors.color7 or "#A6ADC8",
        text_muted = colors.color8 or "#6C7086",
        accent = colors.color15 or "#F5F5F5",
        accent_alt = colors.color1 or "#F5F5F5",
        transparent = "#00000000",
        primary = colors.color4 or "#7AA2F7",
        secondary = colors.color1 or "#ff0000",
        foreground = colors.color15 or "#ECEFF4",
        warning = colors.color3 or "#ffb86c",
        error = colors.color1 or "#ff5555",
        wallpaper = WalColors.get_current_wallpaper()
    }
    

    return result
end

function WalColors.get_current_wallpaper()
    local wal_file = os.getenv("HOME") .. "/.cache/wal/wal"
    
    local file = io.open(wal_file, "r")
    if not file then

        return "/home/panic-attack/wallpapers/wallpaper.jpg"
    end
    
    local wallpaper_path = file:read("*line")
    file:close()
    
    if wallpaper_path and wallpaper_path ~= "" then

        return wallpaper_path
    else

        return "/home/panic-attack/wallpapers/wallpaper.jpg"
    end
end

-- Для обратной совместимости
function WalColors.load_colors()
    local colors = WalColors.load_colors_from_file()
    if colors then
        return {
            colors = colors,
            wallpaper = colors.wallpaper
        }
    end
    return nil
end

return WalColors
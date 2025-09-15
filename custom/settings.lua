-- ~/.config/awesome/custom/settings.lua
local settings = {
    -- Цветовая схема
    colors = {
        background = "#1E1E2E",        -- основной тёмный фон
        surface = "#2A2A3C",           -- фон элементов (панели, виджеты)
        text = "#ECEFF4",              -- основной текст
        text_secondary = "#A6ADC8",    -- вторичный текст
        accent = "#7AA2F7",            -- акцентный цвет (небесно-синий)
        accent_alt = "#9D7CD8",        -- дополнительный акцент (фиолетовый)
        
        -- Дополнительные цвета для совместимости
        primary = "#7AA2F7",
        secondary = "#9D7CD8",
        foreground = "#ECEFF4",
        warning = "#ffb86c",
        error = "#ff5555"
    },
    
    -- Шрифты
    fonts = {
        main = "Ubuntu 10",
        mono = "Ubuntu Mono 10",
        icon = "Font Awesome 6 Free 12",
        widget_size = 10
    },
    
    -- Размеры и отступы
    dimensions = {
        border_width = 2,
        corner_radius = 8,
        spacing = 8,
        margin = 4,
        padding = 8
    },
    
    -- Настройки панели
    bar = {
        height = 25,
        position = "top",
        opacity = 0.8,
        background = "#2A2A3C80",  -- прозрачный surface цвет
        foreground = "#ECEFF4",    -- основной текст
        margin = 5
    },
    
    -- Иконки
    icons = {
        player = {
            play = "",
            pause = "󰏤",
            stop = "󰏤",
            next = "󰒭",
            prev = "󰒮",
            shuffle = "󰐝",
            repeat_one = "󰑘",
            repeat_all = "󰑖",
            music = "󰎇"
        },
        
        audio = {
            high = "󰕾",
            medium = "󰕽",
            low = "󰕼",
            muted = "󰕿",
            mic_on = "󰕸",
            mic_off = "󰕺"
        },
        
        system = {
            cpu = "",
            gpu = "󰢮",
            ram = "󰍛"
        }
    },
    
    -- Пути
    paths = {
        wallpaper = "/home/panic-attack/wallpapers/wallpaper.jpg"
    },
    
    -- Команды
    commands = {
        system_monitor = "flatpak run net.nokyan.Resources"
    },
    
    -- Настройки виджетов
    widgets = {
        slider = {
            width = 120,
            height = 6,
            handle_width = 12,
            animation_duration = 0.2
        },
        volume = {
            slider_width = 120,
            bar_height = 6,
            handle_width = 10,
            update_interval = 1.0,
            debounce_timeout = 0.15
        },
        clock = {
            show_seconds = false,
            show_date = true,
            show_time = true,
            date_format = "%d.%m",
            time_format = "%H:%M",
            separator = " "
        }
    }
}

return settings
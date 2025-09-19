-- ~/.config/awesome/custom/settings.lua
local settings = {
    -- Цветовая схема
    colors = {
        background = "#1E1E2E",        -- основной тёмный фон
        surface = "#2A2A3C",           -- фон элементов (панели, виджеты)
        text = "#ECEFF4",              -- основной текст
        text_secondary = "#A6ADC8",    -- вторичный текст
        text_muted = "#6C7086",        -- приглушенный текст (более темный)
        accent = "#F5F5F5",            -- акцентный цвет (более насыщенная версия основного текста)
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
        main = "DejaVu Sans 10",
        mono = "DejaVu Sans Mono 10",
        icon = "Symbols Nerd Font 12",
        material = "Material Design Icons Desktop 12",
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
        height = 28,
        position = "top",
        opacity = 0.8,
        background = "#2A2A3C80",  -- прозрачный surface цвет
        foreground = "#ECEFF4",    -- основной текст
        margin = 0
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
        
        weather = {
            clear_day = "",
            clear_night = "",
            cloudy = "󰖐",
            fog = "",
            heavy_rain = "",
            heavy_snow = "",
            light_rain = "",
            light_snow = "",
            partly_cloudy_day = "",
            partly_cloudy_night = "",
            rain = "",
            snow = "",
            thunderstorm = "",
            wind = "",
            default = "",
            -- Параметры погоды
            humidity = "",
            wind_speed = "󰖝",
            pressure = ""
        },
        
        system = {
            cpu = "",
            gpu = "󰢮",
            ram = "󰍛",
            awesome = "",
            power = "󰐥",
            poweroff = "󰐥",
            sleep = "󰤄",
            logout = "󰍃",
            reboot = "󰜉",
            cancel = "󰐍",
            execute = "󰐄",
            terminal = "󰆍",
            launcher = "󰀻",
            screenshot = ""
        }
    },
    
    -- Пути
    paths = {
        wallpaper = "/home/panic-attack/wallpapers/wallpaper.jpg"
    },
    
    -- Команды
    commands = {
        system_monitor = "flatpak run net.nokyan.Resources",
        weather_app = "gnome-weather",
        screenshot = "flameshot gui",
        launcher = "rofi -show drun"
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
        },
        notifications = {
            timeout = 5,
            width = 300,
            height = 80,
            icon_size = 48,
            max_visible = 5,
            default_icon = "󰵙"
        },
        desktop_notifications = {
            position = "top_middle",  -- top_left, top_middle, top_right, bottom_left, bottom_middle, bottom_right
            width = 350,
            margin = 20,
            spacing = 8
        },
        list_item = {
            height = 70,  -- высота элементов в списках
            spacing = 8,  -- отступ между элементами в списке
            gap_between_lists = 15  -- отступ между списком плееров и уведомлений
        },
        weather = {
            width = 200,
            height = 120
        },
        control_center = {
            width = 200
        }
    },
    
    -- API настройки
    api = {
        weather = {
            user_agent = "awesome-weather-widget/1.0 (panic-attack@example.com)",
            latitude = "47.91",  -- Кривой Рог
            longitude = "33.39",
            update_interval = 600  -- 10 минут
        }
    }
}

return settings
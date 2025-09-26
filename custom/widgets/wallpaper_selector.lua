-- ~/.config/awesome/custom/widgets/wallpaper_selector.lua
local gears = require("gears")
local wibox = require("wibox")
local awful = require("awful")

local WallpaperSelector = {}
WallpaperSelector.__index = WallpaperSelector

local Button2 = require("custom.widgets.button_2")
local beautiful = require("beautiful")
local GlobalStorage = require("custom.utils.global_storage")
local settings = require("custom.settings")
local click_to_hide = require("custom.utils.click_to_hide_positioned")

local KeyboardList = require("custom.widgets.keyboard_list")
local CustomScroll = require("custom.widgets.custom_scroll")
local Text = require("custom.widgets.base_widgets.text")

-- Функция для создания пропорционального imagebox
local function proportional_imagebox(img, max_width)
    local widget = wibox.widget {
        image = img,
        resize = true,
        widget = wibox.widget.imagebox,
    }

    return wibox.widget {
        widget,
        fit = function(_, context, width, height)
            if not img then return max_width or 280, 180 end
            local ok, iw, ih = pcall(gears.surface.get_size, img)
            if not ok or not iw or not ih or iw == 0 or ih == 0 then
                return max_width or 280, 180
            end
            width = math.min(width, max_width or width)
            local ratio = ih / iw
            return width, width * ratio
        end,
        layout = wibox.container.constraint,
    }
end

function WallpaperSelector.new()
    local self = setmetatable({}, WallpaperSelector)
    
    self.selected_wallpaper = nil
    self.wallpapers = {}
    self:_scan_wallpapers()
    self:_create_widgets()
    
    -- Слушаем изменения состояния
    GlobalStorage.listen("wallpaper_selector_open", function(value)
        if value then
            self:_show()
        else
            self:_hide()
        end
    end)
    
    return self
end

function WallpaperSelector:_scan_wallpapers()
    local wallpaper_dir = settings.paths.wallpaper_dir or "/home/panic-attack/wallpapers/"
    local debug_logger = require("custom.utils.debug_logger")
    
    debug_logger.log("WALLPAPER_SELECTOR: сканируем папку: " .. wallpaper_dir)
    
    awful.spawn.easy_async_with_shell("find '" .. wallpaper_dir .. "' -type f \\( -name '*.jpg' -o -name '*.jpeg' -o -name '*.png' \\) | sort", function(stdout)
        self.wallpapers = {}
        for line in stdout:gmatch("[^\r\n]+") do
            local filename = line:match("([^/]+)$")
            table.insert(self.wallpapers, {
                path = line,
                name = filename
            })
        end
        debug_logger.log("WALLPAPER_SELECTOR: найдено " .. #self.wallpapers .. " обоев")
        self:_update_list()
    end)
end

function WallpaperSelector:_create_widgets()
    local screen_geo = awful.screen.focused().geometry
    
    -- Константы размеров
    self.BUTTON_HEIGHT = 32
    self.BUTTON_SPACING = 2
    self.SCROLL_HEIGHT = 280
    
    -- Список обоев с поддержкой клавиатуры
    self.keyboard_list = KeyboardList.new({
        spacing = self.BUTTON_SPACING,
        button_config = {
            width = 240,
            height = self.BUTTON_HEIGHT,
            halign = "left"
        },
        is_visible = function()
            return self.wibox and self.wibox.visible
        end,
        on_select = function(wallpaper, index)
            self:_select_wallpaper(wallpaper, index)
            -- Прокручиваем до выбранного элемента
            if self.scroll_container then
                self.scroll_container:scroll_to_element(index, self.BUTTON_HEIGHT, self.BUTTON_SPACING)
            end
        end,
        on_click = function(wallpaper, index)
            self:_select_wallpaper(wallpaper, index)
        end,
        on_submit = function(wallpaper, index)
            self:_apply_wallpaper()
        end
    })
    
    -- Создаем скролл контейнер
    self.scroll_container = CustomScroll.new({
        height = self.SCROLL_HEIGHT,
        step = self.BUTTON_HEIGHT + self.BUTTON_SPACING
    })
    
    -- Превью
    self.preview_container = wibox.widget {
        {
            forced_width = 400,
            forced_height = 250,
            widget = wibox.widget.base.empty_widget()
        },
        halign = "center",
        valign = "center",
        widget = wibox.container.place
    }
    
    -- Массив кнопок для управления выделением
    self.wallpaper_buttons = {}
    
    -- Кнопки
    local apply_button = Button2.new({
        content = Text.new({
            text = "Применить",
            font = settings.fonts.main .. " 12",
            theme_color = "text"
        }),
        width = 120,
        height = 35,
        on_click = function()
            self:_apply_wallpaper()
        end
    })
    
    local close_button = Button2.new({
        content = Text.new({
            text = "Закрыть",
            font = settings.fonts.main .. " 12",
            theme_color = "text"
        }),
        width = 120,
        height = 35,
        on_click = function()
            if self.stop_click_hide then
                self.stop_click_hide()
            end
            self.hide_callback()
        end
    })
    
    -- Основной контент
    local title = Text.new({
        text = "Выбор обоев",
        font = settings.fonts.main .. " Bold 16",
        theme_color = "text"
    })
    
    -- Первый ряд: список и превью (фиксированная высота)
    local first_row = wibox.widget {
        {
            {
                self.scroll_container:get_widget(),
                forced_width = 250,
                widget = wibox.container.constraint
            },
            {
                forced_width = 20,
                widget = wibox.widget.base.empty_widget()
            },
            {
                self.preview_container,
                forced_width = 400,
                widget = wibox.container.constraint
            },
            layout = wibox.layout.align.horizontal
        },
        forced_height = 300,
        widget = wibox.container.constraint
    }
    
    -- Второй ряд: кнопки (фиксированная высота)
    local second_row = wibox.widget {
        {
            {
                apply_button.widget,
                close_button.widget,
                spacing = 20,
                layout = wibox.layout.fixed.horizontal
            },
            halign = "center",
            widget = wibox.container.place
        },
        forced_height = 50,
        widget = wibox.container.constraint
    }
    
    local content = wibox.widget {
        title,
        first_row,
        second_row,
        spacing = 20,
        layout = wibox.layout.fixed.vertical
    }
    
    -- Создаем wibox
    self.wibox = wibox({
        x = (screen_geo.width - 720) / 2,
        y = (screen_geo.height - 470) / 2,
        width = 720,
        height = 470,
        bg = beautiful.background,
        shape = gears.shape.rounded_rect,
        visible = false,
        ontop = true
    })
    
    self.wibox:setup({
        content,
        margins = 30,
        widget = wibox.container.margin
    })
    
    -- Настраиваем click_to_hide
    local click_outside_callback = function()
        GlobalStorage.set("wallpaper_selector_open", false)
    end
    
    self.start_click_hide, self.stop_click_hide = click_to_hide(
        self.wibox,
        click_outside_callback,
        function()
            return self.wibox.visible
        end
    )
    
    -- Сохраняем ссылку на callback для кнопок
    self.hide_callback = click_outside_callback
end

function WallpaperSelector:_update_list()
    local debug_logger = require("custom.utils.debug_logger")
    debug_logger.log("WALLPAPER_SELECTOR: обновляем список, обоев: " .. #self.wallpapers)
    
    self.keyboard_list:reset()
    
    for i, wallpaper in ipairs(self.wallpapers) do
        local text_widget = wibox.widget {
            markup = '<span color="' .. beautiful.text .. '">' .. wallpaper.name .. '</span>',
            font = settings.fonts.main .. " 10",
            align = "left",
            ellipsize = "end",
            widget = wibox.widget.textbox
        }
        
        self.keyboard_list:add_item(wallpaper, text_widget)
    end
    
    -- Обновляем высоту скролла и устанавливаем контент
    local total_height = #self.wallpapers * (self.BUTTON_HEIGHT + self.BUTTON_SPACING) - self.BUTTON_SPACING
    self.scroll_container:update_inner_height(total_height)
    self.scroll_container:set_content(self.keyboard_list.widget)
    
    -- Автоматически выбираем первый элемент с полным обновлением
    if #self.wallpapers > 0 then
        self.keyboard_list:select_item(1)
    end
end

function WallpaperSelector:_select_wallpaper(wallpaper, index)
    
    -- Обновляем стили выделения через KeyboardList
    self.keyboard_list:update_selection_style(
        { bg = beautiful.accent, fg = beautiful.background },
        { bg = beautiful.surface, fg = beautiful.text }
    )
    
    self.selected_wallpaper = wallpaper
    
    -- Создаем пропорциональное изображение
    local proportional_img = proportional_imagebox(wallpaper.path, 400)
    
    -- Обновляем контейнер превью
    self.preview_container.widget = proportional_img
end

function WallpaperSelector:_apply_wallpaper()
    if self.selected_wallpaper then
        
        -- Проверяем существование файла
        awful.spawn.easy_async_with_shell("ls -la '" .. self.selected_wallpaper.path .. "'", function(stdout, stderr)
            if stderr and stderr ~= "" then

            end
        end)
        
        -- Выполняем wal с полным логированием
        awful.spawn.easy_async_with_shell("~/.local/bin/wal -i '" .. self.selected_wallpaper.path .. "'", function(stdout, stderr)
            if stderr and stderr ~= "" then

            end
            
            -- Устанавливаем обои через AwesomeWM
            gears.wallpaper.maximized(self.selected_wallpaper.path, awful.screen.focused(), true)
            
            -- Сразу обновляем цвета
            local WalColors = require("custom.utils.wal_colors")
            WalColors.reload_settings_colors()
        end)
        
        if self.stop_click_hide then
            self.stop_click_hide()
        end
        self.hide_callback()
    end
end

function WallpaperSelector:_show()
    -- Пересканируем папку при каждом открытии
    self:_scan_wallpapers()
    
    self.wibox.visible = true
    self.wibox.ontop = true
    self.keyboard_list:start_keygrabber()
    
    if self.start_click_hide then
        
        self.start_click_hide()
    end
end

function WallpaperSelector:_hide()
    
    self.keyboard_list:stop_keygrabber()
    self.wibox.ontop = false
    self.wibox.visible = false
    
    -- Сбрасываем позицию списка к началу при закрытии
    if self.scroll_container then
        self.scroll_container:reset()
    end
    if self.keyboard_list then
        self.keyboard_list:reset_selection()
    end
end

function WallpaperSelector.toggle()
    local is_open = GlobalStorage.get("wallpaper_selector_open") or false
    GlobalStorage.set("wallpaper_selector_open", not is_open)
end

return WallpaperSelector
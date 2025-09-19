-- ~/.config/awesome/custom/widgets/calendar.lua
local wibox = require("wibox")
local awful = require("awful")
local gears = require("gears")
local Provider = require("custom.widgets.provider")
local settings = require("custom.settings")

local Calendar = {}
Calendar.__index = Calendar

function Calendar.new()
    local self = setmetatable({}, Calendar)
    local colors = Provider.get_colors()
    
    -- Получаем текущую дату
    local current_date = os.date("*t")
    local weekdays = {"Воскресенье", "Понедельник", "Вторник", "Среда", "Четверг", "Пятница", "Суббота"}
    local months = {"Январь", "Февраль", "Март", "Апрель", "Май", "Июнь", 
                   "Июль", "Август", "Сентябрь", "Октябрь", "Ноябрь", "Декабрь"}
    
    -- Хедер с датой
    local header = wibox.widget {
        {
            -- Название дня недели (еще меньше)
            {
                text = weekdays[current_date.wday],
                font = settings.fonts.main .. " 12",
                fg = colors.text_secondary,
                align = "left",
                widget = wibox.widget.textbox
            },
            -- Месяц, день и год (bold)
            {
                markup = "<b><span color='" .. colors.accent .. "'>" .. months[current_date.month] .. " " .. current_date.day .. ", " .. current_date.year .. "</span></b>",
                font = settings.fonts.main .. " 12",
                align = "left",
                widget = wibox.widget.textbox
            },
            spacing = 2,
            layout = wibox.layout.fixed.vertical
        },
        margins = {top = 0, bottom = 10, left = 0, right = 0},
        widget = wibox.container.margin
    }
    
    -- Месячный календарь с текущей датой
    self.calendar = wibox.widget {
        date = current_date,
        font = settings.fonts.main .. " 10", -- уменьшенные цифры
        
        spacing = 8,
        week_numbers = false,
        start_sunday = false,
        long_weekdays = false,
        expand_horizontal = true, -- авторастяжение на всю ширину
        fn_embed = function(widget, flag, date)
            if flag == "focus" then
                -- Текущий день в кружке
                return wibox.widget {
                    {
                        widget,
                        margins = 3,
                        widget = wibox.container.margin
                    },
                    bg = colors.accent,
                    fg = colors.background,
                    shape = gears.shape.circle,
                    widget = wibox.container.background
                }
            elseif flag == "weekday" then
                -- Дни недели - меньше и темнее
                if widget.get_text and widget.set_markup then
                    widget:set_markup('<span font="' .. settings.fonts.main .. ' 8" color="' .. colors.text_secondary .. '">' .. widget:get_text() .. '</span>')
                end
                return widget
            end
            return widget
        end,
        widget = wibox.widget.calendar.month
    }
    
    -- Оборачиваем в стилизованный контейнер с padding
    local calendar_container = wibox.widget {
        {
            {
                -- Хедер с датой
                header,
                -- Календарь с фоном, padding и центрированием
                {
                    {
                        {
                            self.calendar,
                            halign = "center",
                            widget = wibox.container.place
                        },
                        margins = {top = 15, bottom = 15, left = 15, right = 25}, -- дополнительный правый padding
                        widget = wibox.container.margin
                    },
                    bg = colors.surface,
                    shape = function(cr, w, h)
                        gears.shape.rounded_rect(cr, w, h, settings.dimensions.corner_radius)
                    end,
                    widget = wibox.container.background
                },
                spacing = 0,
                layout = wibox.layout.fixed.vertical
            },
            widget = wibox.container.background -- убрал отступы
        },
       
        bg = "transparent", -- убрал фон главного контейнера
        widget = wibox.container.background
    }
    
    -- Оборачиваем в place чтобы не растягивался
    self.widget = wibox.widget {
        calendar_container,
        valign = "top",
        widget = wibox.container.place
    }
    
    return self
end

function Calendar:update()
    local current_date = os.date("*t")
    local weekdays = {"Воскресенье", "Понедельник", "Вторник", "Среда", "Четверг", "Пятница", "Суббота"}
    local months = {"Январь", "Февраль", "Март", "Апрель", "Май", "Июнь", 
                   "Июль", "Август", "Сентябрь", "Октябрь", "Ноябрь", "Декабрь"}
    
    -- Обновляем календарь
    self.calendar.date = current_date
    
    -- Обновляем заголовок (находим виджеты в структуре)
    local colors = Provider.get_colors()
    local header_widgets = self.widget.children[1].children[1].children[1].children
    if header_widgets and #header_widgets >= 2 then
        header_widgets[1].text = weekdays[current_date.wday]
        header_widgets[2].markup = "<b><span color='" .. colors.accent .. "'>" .. months[current_date.month] .. " " .. current_date.day .. ", " .. current_date.year .. "</span></b>"
    end
end

return Calendar
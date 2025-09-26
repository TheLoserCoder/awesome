-- ~/.config/awesome/custom/widgets/calendar.lua
local wibox = require("wibox")
local awful = require("awful")
local gears = require("gears")
local settings = require("custom.settings")

local Calendar = {}
Calendar.__index = Calendar

function Calendar.new()
    local self = setmetatable({}, Calendar)
    local colors = settings.colors
    
    -- Получаем текущую дату
    local current_date = os.date("*t")
    local weekdays = {"Воскресенье", "Понедельник", "Вторник", "Среда", "Четверг", "Пятница", "Суббота"}
    local months = {"Январь", "Февраль", "Март", "Апрель", "Май", "Июнь", 
                   "Июль", "Август", "Сентябрь", "Октябрь", "Ноябрь", "Декабрь"}
    
    -- Создаем текстовые виджеты хедера
    local Text = require("custom.widgets.base_widgets.text")
    
    self.weekday_text = Text.new({
        text = weekdays[current_date.wday],
        theme_color = "text_muted",
        font = settings.fonts.main .. " 16"
    })
    
    self.date_text = Text.new({
        text = months[current_date.month] .. " " .. current_date.day .. ", " .. current_date.year,
        theme_color = "text",
        font = settings.fonts.main .. " Bold 16"
    })
    
    -- Хедер с датой
    local header = wibox.widget {
        {
            self.weekday_text,
            self.date_text,
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
            local Container = require("custom.widgets.base_widgets.container")
            local Text = require("custom.widgets.base_widgets.text")
            
            if flag == "focus" then
                -- Текущий день в кружке
                local day_text = widget.get_text and widget:get_text() or ""
                return Container.new({
                    content = Text.new({
                        text = day_text,
                        theme_color = "background",
                        font = settings.fonts.main .. " 10"
                    }),
                    theme_color = "accent",
                    margins = 3,
                    shape = gears.shape.circle,
                    halign = "center",
                    valign = "center"
                })
            elseif flag == "weekday" then
                -- Дни недели - оборачиваем в круглые контейнеры
                if widget.get_text then
                    local weekday_text = widget:get_text()
                    return Container.new({
                        content = Text.new({
                            text = weekday_text,
                            theme_color = "text_muted",
                            font = settings.fonts.main .. " 8"
                        }),
                        theme_color = "transparent",
                        margins = 3,
                        shape = gears.shape.circle,
                        halign = "center",
                        valign = "center"
                    })
                end
                return widget
            elseif flag == "normal" then
                -- Обычные дни месяца - оборачиваем в круглые контейнеры
                if widget.get_text then
                    local day_text = widget:get_text()
                    return Container.new({
                        content = Text.new({
                            text = day_text,
                            theme_color = "text",
                            font = settings.fonts.main .. " 10"
                        }),
                        theme_color = "transparent",
                        margins = 3,
                        shape = gears.shape.circle,
                        halign = "center",
                        valign = "center"
                    })
                end
                return widget
            elseif flag == "monthheader" or flag == "header" or flag == "month" then
                -- Месяц в шапке - увеличиваем и центрируем
                if widget.get_text then
                    local month_text = widget:get_text():match("^(%S+)")
                    return wibox.widget {
                        {
                            Text.new({
                                text = month_text,
                                theme_color = "text",
                                font = settings.fonts.main .. " Bold 12"
                            }),
                            halign = "center",
                            widget = wibox.container.place
                        },
                        widget = wibox.container.margin
                    }
                end
                return widget
            end
            return widget
        end,
        widget = wibox.widget.calendar.month
    }
    
    -- Оборачиваем в стилизованный контейнер с padding
    local Container = require("custom.widgets.base_widgets.container")
    local calendar_container = wibox.widget {
        header,
        Container.surface({
            content = wibox.widget {
                {
                    self.calendar,
                    halign = "center",
                    widget = wibox.container.place
                },
                widget = wibox.container.margin
            },
            margins = {top = 15, bottom = 15, left = 15, right = 25},
            halign = "center"
        }),
        spacing = 0,
        layout = wibox.layout.fixed.vertical
    }
    
    -- Календарь растягивается во всю ширину
    self.widget = calendar_container
    
    return self
end

function Calendar:update()
    local current_date = os.date("*t")
    local weekdays = {"Воскресенье", "Понедельник", "Вторник", "Среда", "Четверг", "Пятница", "Суббота"}
    local months = {"Январь", "Февраль", "Март", "Апрель", "Май", "Июнь", 
                   "Июль", "Август", "Сентябрь", "Октябрь", "Ноябрь", "Декабрь"}
    
    -- Обновляем календарь
    self.calendar.date = current_date
    
    -- Обновляем заголовок
    if self.weekday_text and self.date_text then
        self.weekday_text:update_text(weekdays[current_date.wday])
        self.date_text:update_text(months[current_date.month] .. " " .. current_date.day .. ", " .. current_date.year)
    end
end

return Calendar
-- ~/.config/awesome/custom/widgets/system_monitor.lua
local gears = require("gears")
local wibox = require("wibox")
local awful = require("awful")

local SystemMonitor = {}
SystemMonitor.__index = SystemMonitor

local settings = require("custom.settings")
local Button = require("custom.widgets.button")

function SystemMonitor.new()
    local self = setmetatable({}, SystemMonitor)
    
    self.cpu_percent = 0
    self.gpu_percent = 0
    self.ram_percent = 0
    self.prev_total = 0
    self.prev_idle = 0
    
    self:_create_widgets()
    self:_start_monitoring()
    
    return self
end

function SystemMonitor:_create_widgets()
    -- CPU иконка и текст
    self.cpu_icon = wibox.widget {
        text = settings.icons.system.cpu,
        font = settings.fonts.icon,
        align = "center",
        valign = "center",
        widget = wibox.widget.textbox
    }
    
    self.cpu_text = wibox.widget {
        text = "0%",
        font = "Ubuntu " .. settings.fonts.widget_size,
        align = "center",
        valign = "center",
        widget = wibox.widget.textbox
    }
    
    -- RAM иконка и текст
    self.ram_icon = wibox.widget {
        text = settings.icons.system.ram,
        font = settings.fonts.icon,
        align = "center",
        valign = "center",
        widget = wibox.widget.textbox
    }
    
    self.ram_text = wibox.widget {
        text = "0%",
        font = "Ubuntu " .. settings.fonts.widget_size,
        align = "center",
        valign = "center",
        widget = wibox.widget.textbox
    }
    
    -- GPU иконка и текст
    self.gpu_icon = wibox.widget {
        text = settings.icons.system.gpu,
        font = settings.fonts.icon,
        align = "center",
        valign = "center",
        widget = wibox.widget.textbox
    }
    
    self.gpu_text = wibox.widget {
        text = "0%",
        font = "Ubuntu " .. settings.fonts.widget_size,
        align = "center",
        valign = "center",
        widget = wibox.widget.textbox
    }
    
    -- Содержимое кнопки
    local content = wibox.widget {
        {
            self.cpu_icon,
            self.cpu_text,
            spacing = 4,
            layout = wibox.layout.fixed.horizontal
        },
        {
            self.ram_icon,
            self.ram_text,
            spacing = 4,
            layout = wibox.layout.fixed.horizontal
        },
        {
            self.gpu_icon,
            self.gpu_text,
            spacing = 4,
            layout = wibox.layout.fixed.horizontal
        },
        spacing = 8,
        layout = wibox.layout.fixed.horizontal
    }
    
    -- Оборачиваем в кнопку
    self.button = Button.new({
        content = content,
        on_click = function()
            awful.spawn(settings.commands.system_monitor)
        end
    })
    
    self.widget = self.button.widget
end

function SystemMonitor:_start_monitoring()
    -- Таймер для обновления данных
    self.timer = gears.timer {
        timeout = 2,
        call_now = true,
        autostart = true,
        callback = function()
            self:_update_cpu()
            self:_update_ram()
            self:_update_gpu()
        end
    }
end

function SystemMonitor:_update_cpu()
    awful.spawn.easy_async_with_shell("grep 'cpu ' /proc/stat", function(stdout)
        local user, nice, system, idle, iowait, irq, softirq, steal =
            stdout:match("cpu%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)")
        local idle_time = tonumber(idle) + tonumber(iowait)
        local total_time = tonumber(user) + tonumber(nice) + tonumber(system) +
                           idle_time + tonumber(irq) + tonumber(softirq) + tonumber(steal)

        local diff_idle = idle_time - self.prev_idle
        local diff_total = total_time - self.prev_total
        local usage = 0
        if diff_total > 0 then
            usage = (diff_total - diff_idle) / diff_total * 100
        end

        self.prev_total, self.prev_idle = total_time, idle_time
        self.cpu_percent = math.floor(usage)
        self.cpu_text:set_text(self.cpu_percent .. "%")
    end)
end

function SystemMonitor:_update_ram()
    awful.spawn.easy_async_with_shell("free | grep Mem", function(stdout)
        local total, used = stdout:match("Mem:%s+(%d+)%s+(%d+)")
        if total and used then
            local usage = (tonumber(used) / tonumber(total)) * 100
            self.ram_percent = math.floor(usage)
            self.ram_text:set_text(self.ram_percent .. "%")
        end
    end)
end

function SystemMonitor:_update_gpu()
    awful.spawn.easy_async_with_shell(
        "nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null || echo '0'",
        function(stdout)
            local gpu_usage = tonumber(stdout:match("([%d%.]+)"))
            if gpu_usage then
                self.gpu_percent = math.floor(gpu_usage)
                self.gpu_text:set_text(self.gpu_percent .. "%")
            end
        end
    )
end

return SystemMonitor
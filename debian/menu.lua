-- automatically generated file. Do not edit (see /usr/share/doc/menu/html)

local awesome = awesome

Debian_menu = {}

Debian_menu["Debian_Оконные_менеджеры"] = {
	{"awesome",function () awesome.exec("/usr/bin/awesome") end,"/usr/share/pixmaps/awesome.xpm"},
}
Debian_menu["Debian_Приложения_Оболочки"] = {
	{"Bash", "x-terminal-emulator -e ".."/bin/bash --login"},
	{"Dash", "x-terminal-emulator -e ".."/bin/dash -i"},
	{"Sh", "x-terminal-emulator -e ".."/bin/sh --login"},
}
Debian_menu["Debian_Приложения_Системные_Администрирование"] = {
	{"Debian Task selector", "x-terminal-emulator -e ".."su-to-root -c tasksel"},
}
Debian_menu["Debian_Приложения_Системные"] = {
	{ "Администрирование", Debian_menu["Debian_Приложения_Системные_Администрирование"] },
}
Debian_menu["Debian_Приложения"] = {
	{ "Оболочки", Debian_menu["Debian_Приложения_Оболочки"] },
	{ "Системные", Debian_menu["Debian_Приложения_Системные"] },
}
Debian_menu["Debian"] = {
	{ "Оконные менеджеры", Debian_menu["Debian_Оконные_менеджеры"] },
	{ "Приложения", Debian_menu["Debian_Приложения"] },
}

debian = { menu = { Debian_menu = Debian_menu } }
return debian
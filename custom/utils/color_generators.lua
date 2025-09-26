-- ~/.config/awesome/custom/utils/color_generators.lua


local ColorGenerators = {}

function ColorGenerators.generate_rofi_colors(colors)
    return string.format([[
* {
    background: %s;
    surface: %s;
    text: %s;
    text-secondary: %s;
    accent: %s;
    accent-alt: %s;
}
]], colors.background or "#1E1E2E",
     colors.surface or "#2A2A3C", 
     colors.text or "#ECEFF4",
     colors.text_secondary or "#A6ADC8",
     colors.accent or "#F5F5F5",
     colors.accent_alt or "#6C7086")
end

function ColorGenerators.generate_all()
    local settings = require("custom.settings")
    
    for _, generator_config in ipairs(settings.color_generators) do
        local success, result = pcall(generator_config.generator, settings.colors)
        if success then
            local output_file = io.open(generator_config.path, "w")
            if output_file then
                output_file:write(result)
                output_file:close()

            else

            end
        else

        end
    end
end

return ColorGenerators
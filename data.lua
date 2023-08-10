
local constants = require("__asher_sky__/constants")

for animation_name, animation_data in pairs(constants.ability_data) do
    local animation = {
        type = "animation",
        name = animation_name,
        filename = "__asher_sky__/graphics/" .. animation_data.filename,
        width = animation_data.width,
        height = animation_data.height,
        frame_count = animation_data.frame_count,
        line_length = animation_data.line_length,
        animation_speed = 1,
        scale = 1,
    }
    data:extend{animation}
end

for _, character_prototype in pairs(data.raw.character) do
    character_prototype.healing_per_tick = 0
end
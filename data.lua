
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

local discharge_defender = table.deepcopy(data.raw["combat-robot"]["defender"])
discharge_defender.name = "discharge-defender"
discharge_defender.attack_parameters = table.deepcopy(data.raw["active-defense-equipment"]["discharge-defense-equipment"].attack_parameters)
discharge_defender.attack_parameters.cooldown = 55
discharge_defender.time_to_live = 120
data:extend{discharge_defender}

local no_damage_laser_beam = table.deepcopy(data.raw["beam"]["laser-beam"])
no_damage_laser_beam.name = "no-damage-laser-beam"
no_damage_laser_beam.action = nil
data:extend{no_damage_laser_beam}

local font_size = 25

local arena_gui_font_default = table.deepcopy(data.raw["font"]["default"])
arena_gui_font_default.name = "arena-gui-default"
arena_gui_font_default.size = font_size
data:extend{arena_gui_font_default}

local arena_gui_font_default_semibold = table.deepcopy(data.raw["font"]["default-semibold"])
arena_gui_font_default_semibold.name = "arena-gui-default-semibold"
arena_gui_font_default_semibold.size = font_size
data:extend{arena_gui_font_default_semibold}

local arena_gui_font_default_bold = table.deepcopy(data.raw["font"]["default-bold"])
arena_gui_font_default_bold.name = "arena-gui-default-bold"
arena_gui_font_default_bold.size = font_size
data:extend{arena_gui_font_default_bold}


local tile_tiers_by_name = {
    ["stone-path"] = 1,
    ["concrete"] = 2,
    ["refined-concrete"] = 3,
    ["red-refined-concrete"] = 4,
    ["green-refined-concrete"] = 5,
    ["blue-refined-concrete"] = 6,
    ["orange-refined-concrete"] = 7,
    ["yellow-refined-concrete"] = 8,
    ["pink-refined-concrete"] = 9,
    ["purple-refined-concrete"] = 10,
    ["black-refined-concrete"] = 11,
    ["brown-refined-concrete"] = 12,
    ["cyan-refined-concrete"] = 13,
    ["acid-refined-concrete"] = 14,
}

local tile_tiers_by_order = {}
for tile_name, order in pairs(tile_tiers_by_name) do
    table.insert(tile_tiers_by_order, order, tile_name)
end

local difficulty_offsets = {
    easy = { x = -7, y = -8 },
    normal = { x = 0, y = -8 },
    hard = { x = 7, y = -8 },
}
local ability_offsets = {
    ability_1 = { x = -7, y = 8 },
    ability_2 = { x = 0, y = 8 },
    ability_3 = { x = 7, y = 8 },
}
local top_right_offset = { x = 2, y = -2}
local bottom_right_offset = { x = 2, y = 1}
local bottom_left_offset = { x = -3, y = 1}
local top_left_offset = { x = -3, y = -2}
local difficulty_tile_names = {
    easy = "green-refined-concrete",
    normal = "yellow-refined-concrete",
    hard = "red-refined-concrete",
}
local walkway_tiles = {
    easy = {
        ["hazard-concrete-right"] = {
            {x = -7, y = -3},
            {x = -7, y = -4},
            {x = -7, y = -5},
            {x = -7, y = -6},
        },
        ["hazard-concrete-left"] = {
            {x = -8, y = -3},
            {x = -8, y = -4},
            {x = -8, y = -5},
            {x = -8, y = -6},
        },
    },
    normal = {
        ["hazard-concrete-right"] = {
            {x = 0, y = -3},
            {x = 0, y = -4},
            {x = 0, y = -5},
            {x = 0, y = -6},
        },
        ["hazard-concrete-left"] = {
            {x = -1, y = -3},
            {x = -1, y = -4},
            {x = -1, y = -5},
            {x = -1, y = -6},
        },
    },
    hard = {
        ["hazard-concrete-right"] = {
            {x = 7, y = -3},
            {x = 7, y = -4},
            {x = 7, y = -5},
            {x = 7, y = -6},
        },
        ["hazard-concrete-left"] = {
            {x = 6, y = -3},
            {x = 6, y = -4},
            {x = 6, y = -5},
            {x = 6, y = -6},
        },
    },
    ability_1 = {
        ["hazard-concrete-left"] = {
            {x = -7, y = 2},
            {x = -7, y = 3},
            {x = -7, y = 4},
            {x = -7, y = 5},
        },
        ["hazard-concrete-right"] = {
            {x = -8, y = 2},
            {x = -8, y = 3},
            {x = -8, y = 4},
            {x = -8, y = 5},
        },
    },
    ability_2 = {
        ["hazard-concrete-left"] = {
            {x = 0, y = 2},
            {x = 0, y = 3},
            {x = 0, y = 4},
            {x = 0, y = 5},
        },
        ["hazard-concrete-right"] = {
            {x = -1, y = 2},
            {x = -1, y = 3},
            {x = -1, y = 4},
            {x = -1, y = 5},
        },
    },
    ability_3 = {
        ["hazard-concrete-left"] = {
            {x = 7, y = 2},
            {x = 7, y = 3},
            {x = 7, y = 4},
            {x = 7, y = 5},
        },
        ["hazard-concrete-right"] = {
            {x = 6, y = 2},
            {x = 6, y = 3},
            {x = 6, y = 4},
            {x = 6, y = 5},
        },
    },
}

---@enum ability_data
local ability_data = {
    slash = {
        filename = "60FPS_FA01_01_Slash.png",
        frame_count = 30,
        line_length = 5,
        width = 192,
        height = 192,
        target = "character",
        default_cooldown = 60 * 2,
        default_radius = 5,
        default_damage = 5,
        damage_multiplier = 2,
        radius_multiplier = 1.25,
        cooldown_multiplier = 10,
        upgrade_order = {
            "radius",
            "damage",
            "radius",
            "damage",
            "radius",
            "cooldown",
            "damage",
            "radius",
            "damage",
            "cooldown",
            "radius",
            "damage",
            "damage",
            "cooldown",
            "radius",
            "damage",
            "damage",
            "cooldown",
            "radius",
            "damage",
            "cooldown",
            "damage",
            "cooldown",
            "damage",
            "cooldown",
            "damage",
            "damage",
            "damage",
        }
    },
    thrust = {
        filename = "60FPS_FA01_02_Thrust.png",
        frame_count = 30,
        line_length = 5,
        width = 192,
        height = 192,
        target = "character",
        default_cooldown = 60 * 1.5,
        default_radius = 1.5,
        default_damage = 10,
        damage_multiplier = 1.5,
        radius_multiplier = 2,
        cooldown_multiplier = 0.5,
    },
    punch = {
        filename = "60FPS_FA01_03_Punch.png",
        frame_count = 30,
        line_length = 5,
        width = 192,
        height = 192,
        target = "position",
        default_cooldown = 60 * 1.5,
        default_radius = 1.5,
        default_damage = 10,
        damage_multiplier = 1.5,
        radius_multiplier = 1,
        cooldown_multiplier = 10,
        upgrade_order = {
            "radius",
            "damage",
            "cooldown",
            "radius",
            "damage",
            "cooldown",
            "radius",
            "damage",
            "cooldown",
            "radius",
            "damage",
            "cooldown",
            "radius",
            "damage",
            "cooldown",
            "damage",
            "cooldown",
            "damage",
            "damage",
            "damage",
            "damage",
            "damage",
            "damage",
            "damage",
        }
    },
    buff = {
        filename = "60FPS_FA01_04_Buff.png",
        frame_count = 60,
        line_length = 5,
        width = 192,
        height = 192,
        target = "position",
        default_cooldown = 60 * 6,
        default_radius = 1.5,
        default_damage = 10,
        damage_multiplier = 1.5,
        radius_multiplier = 2,
        cooldown_multiplier = 0.5,
    },
    shimmer = {
        filename = "60FPS_FA01_06_Shimmer.png",
        frame_count = 60,
        line_length = 5,
        width = 192,
        height = 192,
        target = "character",
        default_cooldown = 60 * 10,
        default_radius = 1.5,
        default_damage = 0,
        damage_multiplier = 1,
        radius_multiplier = 2,
        cooldown_multiplier = 0.5,
    },
    cure = {
        filename = "60FPS_FA01_07_Cure.png",
        frame_count = 70,
        line_length = 5,
        width = 192,
        height = 192,
        target = "character",
        default_cooldown = 60 * 8,
        default_radius = 1,
        default_damage = -0.25,
        damage_multiplier = 1.125,
        radius_multiplier = 2,
        cooldown_multiplier = 30,
        upgrade_order = {
            "damage",
            "damage",
            "damage",
            "cooldown",
            "damage",
            "damage",
            "damage",
            "cooldown",
            "damage",
            "damage",
            "cooldown",
            "damage",
            "damage",
            "cooldown",
        }
    },
    shield = {
        filename = "60FPS_FA01_08_Shield.png",
        frame_count = 60,
        line_length = 5,
        width = 192,
        height = 192,
        target = "character",
        default_cooldown = 60 * 10,
        default_radius = 1.5,
        default_damage = 10,
        damage_multiplier = 1.5,
        radius_multiplier = 2,
        cooldown_multiplier = 0.5,
    },
    barrier = {
        filename = "60FPS_FA01_09_Barrier.png",
        frame_count = 100,
        line_length = 5,
        width = 192,
        height = 192,
        target = "character",
        default_cooldown = 60 * 10,
        default_radius = 1.5,
        default_damage = 10,
        damage_multiplier = 1.5,
        radius_multiplier = 2,
        cooldown_multiplier = 0.5,
    },
    burst = {
        filename = "60FPS_FA01_10_Burst.png",
        frame_count = 100,
        line_length = 5,
        width = 192,
        height = 192,
        target = "position",
        default_cooldown = 60 * 7,
        default_radius = 1,
        default_damage = 25,
        damage_multiplier = 2,
        radius_multiplier = 2,
        cooldown_multiplier = 35,
        upgrade_order = {
            "radius",
            "cooldown",
            "damage",
            "radius",
            "damage",
            "cooldown",
            "radius",
            "damage",
            "cooldown",
            "damage",
            "radius",
            "cooldown",
            "damage",
            "radius",
            "damage",
            "damage",
            "damage",
            "damage",
            "damage",
        }
    },
    rocket_launcher = {
        filename = "60FPS_FA01_06_Shimmer.png",
        frame_count = 60,
        line_length = 5,
        width = 192,
        height = 192,
        target = "position",
        default_cooldown = 60 * 0.5,
        default_radius = 15,
        default_damage = 1,
        damage_multiplier = 1.5,
        radius_multiplier = 5,
        cooldown_multiplier = 1,
        upgrade_order = {
            "cooldown",
            "cooldown",
            "cooldown",
            "cooldown",
            "cooldown",
            "cooldown",
            "cooldown",
            "cooldown",
            "cooldown",
            "cooldown",
            "cooldown",
            "cooldown",
            "cooldown",
            "cooldown",
            "cooldown",
            "cooldown",
            "cooldown",
            "cooldown",
            "cooldown",
            "cooldown",
            "cooldown",
            "radius",
            "cooldown",
            "cooldown",
            "cooldown",
            "cooldown",
            "radius",
            "cooldown",
            "cooldown",
            "cooldown",
            "radius",
            "cooldown",
            "cooldown",
            "radius",
            "radius",
        },
    },
    pavement = {
        filename = "60FPS_FA01_06_Shimmer.png",
        frame_count = 60,
        line_length = 5,
        width = 192,
        height = 192,
        target = "position",
        default_cooldown = 60 * 0.85,
        default_radius = 1,
        default_damage = 1,
        damage_multiplier = 1.5,
        radius_multiplier = 1,
        cooldown_multiplier = 2,
        upgrade_order = {
            "cooldown",
            "cooldown",
            "cooldown",
            "cooldown",
            "radius",
            "cooldown",
            "cooldown",
            "cooldown",
            "cooldown",
            "radius",
            "cooldown",
            "cooldown",
            "cooldown",
            "cooldown",
            "radius",
            "cooldown",
            "cooldown",
            "cooldown",
            "cooldown",
        },
    },
    beam_blast = {
        filename = "60FPS_FA01_06_Shimmer.png",
        frame_count = 60,
        line_length = 5,
        width = 192,
        height = 192,
        target = "position",
        default_cooldown = 60 * 3.25,
        default_radius = 5,
        default_damage = 33,
        damage_multiplier = 1.5,
        radius_multiplier = 3,
        cooldown_multiplier = 10,
        upgrade_order = {
            "cooldown",
            "cooldown",
            "cooldown",
            "radius",
            "cooldown",
            "cooldown",
            "cooldown",
            "radius",
            "cooldown",
            "cooldown",
            "cooldown",
            "radius",
            "cooldown",
            "cooldown",
            "cooldown",
            "radius",
        },
    },
    discharge_defender = {
        filename = "60FPS_FA01_06_Shimmer.png",
        frame_count = 60,
        line_length = 5,
        width = 192,
        height = 192,
        target = "position",
        default_cooldown = 60 * 6,
        default_radius = 1,
        default_damage = 1,
        damage_multiplier = 1,
        radius_multiplier = 1,
        cooldown_multiplier = 20,
        upgrade_order = {
            "cooldown",
            "cooldown",
            "cooldown",
            "cooldown",
            "cooldown",
            "cooldown",
            "cooldown",
            "cooldown",
            "cooldown",
            "cooldown",
            "cooldown",
            "cooldown",
            "cooldown",
            "cooldown",
        },
    },
    destroyer = {
        filename = "60FPS_FA01_06_Shimmer.png",
        frame_count = 60,
        line_length = 5,
        width = 192,
        height = 192,
        target = "position",
        default_cooldown = 60 * 35,
        default_radius = 1,
        default_damage = 1,
        damage_multiplier = 1,
        radius_multiplier = 1,
        cooldown_multiplier = 66,
        upgrade_order = {
            "cooldown",
            "cooldown",
            "cooldown",
            "cooldown",
            "cooldown",
            "cooldown",
            "cooldown",
            "cooldown",
            "cooldown",
            "cooldown",
            "cooldown",
            "cooldown",
            "cooldown",
            "cooldown",
            "cooldown",
            "cooldown",
            "cooldown",
            "cooldown",
            "cooldown",
            "cooldown",
        },
    },
    landmine = {
        filename = "60FPS_FA01_06_Shimmer.png",
        frame_count = 60,
        line_length = 5,
        width = 192,
        height = 192,
        target = "position",
        default_cooldown = 60 * 2.75,
        default_radius = 1,
        default_damage = 1,
        damage_multiplier = 1,
        radius_multiplier = 0.5,
        cooldown_multiplier = 19,
        upgrade_order = {
            "cooldown",
            "cooldown",
            "cooldown",
            "radius",
            "cooldown",
            "cooldown",
            "radius",
            "cooldown",
            "cooldown",
            "radius",
            "radius",
        },
    },
    poison_capsule = {
        filename = "60FPS_FA01_06_Shimmer.png",
        frame_count = 60,
        line_length = 5,
        width = 192,
        height = 192,
        target = "position",
        default_cooldown = 60 * 30,
        default_radius = 10,
        default_damage = 1,
        damage_multiplier = 1,
        radius_multiplier = 7,
        cooldown_multiplier = 45,
        upgrade_order = {
            "cooldown",
            "cooldown",
            "cooldown",
            "radius",
            "cooldown",
            "cooldown",
            "radius",
            "cooldown",
            "cooldown",
            "cooldown",
            "radius",
            "radius",
        },
    },
    slowdown_capsule = {
        filename = "60FPS_FA01_06_Shimmer.png",
        frame_count = 60,
        line_length = 5,
        width = 192,
        height = 192,
        target = "position",
        default_cooldown = 60 * 17,
        default_radius = 10,
        default_damage = 1,
        damage_multiplier = 1,
        radius_multiplier = 7,
        cooldown_multiplier = 45,
        upgrade_order = {
            "cooldown",
            "cooldown",
            "cooldown",
            "radius",
            "cooldown",
            "cooldown",
            "radius",
            "cooldown",
            "cooldown",
            "cooldown",
            "radius",
            "radius",
        },
    },
    gun_turret = {
        filename = "60FPS_FA01_06_Shimmer.png",
        frame_count = 60,
        line_length = 5,
        width = 192,
        height = 192,
        target = "position",
        default_cooldown = 60 * 26,
        default_radius = 10,
        default_damage = 1,
        damage_multiplier = 1.5,
        radius_multiplier = 5,
        cooldown_multiplier = 99,
        upgrade_order = {
            "cooldown",
            "cooldown",
            "radius",
            "cooldown",
            "cooldown",
            "cooldown",
            "radius",
            "cooldown",
            "cooldown",
            "cooldown",
            "cooldown",
            "radius",
            "radius",
            "radius",
        },
    },
}

return {
    ability_data = ability_data,
    tile_tiers_by_name = tile_tiers_by_name,
    tile_tiers_by_order = tile_tiers_by_order,
    difficulty_offsets = difficulty_offsets,
    ability_offsets = ability_offsets,
    top_right_offset = top_right_offset,
    bottom_right_offset = bottom_right_offset,
    bottom_left_offset = bottom_left_offset,
    top_left_offset = top_left_offset,
    difficulty_tile_names = difficulty_tile_names,
    walkway_tiles = walkway_tiles,
}
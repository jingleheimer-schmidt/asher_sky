
local constants = require("__asher_sky__/constants")
local difficulty_offsets = constants.difficulty_offsets
local difficulty_tile_names = constants.difficulty_tile_names
local ability_offsets = constants.ability_offsets
local walkway_tiles = constants.walkway_tiles
local top_right_offset = constants.top_right_offset
local bottom_right_offset = constants.bottom_right_offset
local bottom_left_offset = constants.bottom_left_offset
local top_left_offset = constants.top_left_offset

local function reset_lobby_tiles()
    local surface = game.surfaces.lobby
    local tiles = {}
    for difficulty, offset in pairs(difficulty_offsets) do
        table.insert(tiles, {
            name = difficulty_tile_names[difficulty],
            position = {
                x = offset.x + top_right_offset.x,
                y = offset.y + top_right_offset.y,
            },
        })
        table.insert(tiles, {
            name = difficulty_tile_names[difficulty],
            position = {
                x = offset.x + bottom_right_offset.x,
                y = offset.y + bottom_right_offset.y,
            },
        })
        table.insert(tiles, {
            name = difficulty_tile_names[difficulty],
            position = {
                x = offset.x + bottom_left_offset.x,
                y = offset.y + bottom_left_offset.y,
            },
        })
        table.insert(tiles, {
            name = difficulty_tile_names[difficulty],
            position = {
                x = offset.x + top_left_offset.x,
                y = offset.y + top_left_offset.y,
            },
        })
    end
    for ability, offset in pairs(ability_offsets) do
        table.insert(tiles, {
            name = "blue-refined-concrete",
            position = {
                x = offset.x + top_right_offset.x,
                y = offset.y + top_right_offset.y,
            },
        })
        table.insert(tiles, {
            name = "blue-refined-concrete",
            position = {
                x = offset.x + bottom_right_offset.x,
                y = offset.y + bottom_right_offset.y,
            },
        })
        table.insert(tiles, {
            name = "blue-refined-concrete",
            position = {
                x = offset.x + bottom_left_offset.x,
                y = offset.y + bottom_left_offset.y,
            },
        })
        table.insert(tiles, {
            name = "blue-refined-concrete",
            position = {
                x = offset.x + top_left_offset.x,
                y = offset.y + top_left_offset.y,
            },
        })
    end
    for _, walkway in pairs(walkway_tiles) do
        for _, lane in pairs(walkway) do
            for _, position in pairs(lane) do
                table.insert(tiles, {
                    name = "stone-path",
                    position = {
                        x = position.x,
                        y = position.y,
                    },
                })
            end
        end
    end
    surface.set_tiles(tiles)
end

local function update_lobby_tiles()
    local difficulty = global.lobby_options.difficulty
    local surface = game.surfaces.lobby
    local starting_ability = global.lobby_options.starting_ability
    local tiles = {
        {
            name = "refined-hazard-concrete-right",
            position = {
                x = difficulty_offsets[difficulty].x + top_right_offset.x,
                y = difficulty_offsets[difficulty].y + top_right_offset.y,
            },
        },
        {
            name = "refined-hazard-concrete-left",
            position = {
                x = difficulty_offsets[difficulty].x + bottom_right_offset.x,
                y = difficulty_offsets[difficulty].y + bottom_right_offset.y,
            },
        },
        {
            name = "refined-hazard-concrete-right",
            position = {
                x = difficulty_offsets[difficulty].x + bottom_left_offset.x,
                y = difficulty_offsets[difficulty].y + bottom_left_offset.y,
            },
        },
        {
            name = "refined-hazard-concrete-left",
            position = {
                x = difficulty_offsets[difficulty].x + top_left_offset.x,
                y = difficulty_offsets[difficulty].y + top_left_offset.y,
            },
        },
        {
            name = "refined-hazard-concrete-right",
            position = {
                x = ability_offsets[starting_ability].x + top_right_offset.x,
                y = ability_offsets[starting_ability].y + top_right_offset.y,
            },
        },
        {
            name = "refined-hazard-concrete-left",
            position = {
                x = ability_offsets[starting_ability].x + bottom_right_offset.x,
                y = ability_offsets[starting_ability].y + bottom_right_offset.y,
            },
        },
        {
            name = "refined-hazard-concrete-right",
            position = {
                x = ability_offsets[starting_ability].x + bottom_left_offset.x,
                y = ability_offsets[starting_ability].y + bottom_left_offset.y,
            },
        },
        {
            name = "refined-hazard-concrete-left",
            position = {
                x = ability_offsets[starting_ability].x + top_left_offset.x,
                y = ability_offsets[starting_ability].y + top_left_offset.y,
            },
        },
    }
    for tile_name, lane in pairs(walkway_tiles[difficulty]) do
        for _, position in pairs(lane) do
            table.insert(tiles, {
                name = tile_name,
                position = {
                    x = position.x,
                    y = position.y,
                },
            })
        end
    end
    for tile_name, lane in pairs(walkway_tiles[starting_ability]) do
        for _, position in pairs(lane) do
            table.insert(tiles, {
                name = tile_name,
                position = {
                    x = position.x,
                    y = position.y,
                },
            })
        end
    end
    reset_lobby_tiles()
    surface.set_tiles(tiles)
end

---@param lobby_surface LuaSurface
local function create_lobby_text(lobby_surface)
    global.lobby_text = {
        start_level = {
            top = rendering.draw_text{
                text = "Enter",
                surface = lobby_surface,
                target = {x = 21, y = -2},
                color = {r = 1, g = 1, b = 1},
                alignment = "center",
                scale = 3,
                draw_on_ground = true,
            },
            bottom = rendering.draw_text{
                text = "Arena",
                surface = lobby_surface,
                target = {x = 21, y = 0},
                color = {r = 1, g = 1, b = 1},
                alignment = "center",
                scale = 3,
                draw_on_ground = true,
            }
        },
        difficulties = {
            easy = rendering.draw_text{
                text = "Easy",
                surface = lobby_surface,
                target = {x = -7, y = -9},
                color = {r = 1, g = 1, b = 1},
                alignment = "center",
                scale = 3,
                draw_on_ground = true,
            },
            normal = rendering.draw_text{
                text = "Normal",
                surface = lobby_surface,
                target = {x = 0, y = -9},
                color = {r = 1, g = 1, b = 1},
                alignment = "center",
                scale = 3,
                draw_on_ground = true,
            },
            hard = rendering.draw_text{
                text = "Hard",
                surface = lobby_surface,
                target = {x = 7, y = -9},
                color = {r = 1, g = 1, b = 1},
                alignment = "center",
                scale = 3,
                draw_on_ground = true,
            },
        },
        starting_abilities = {
            ability_1 = rendering.draw_text{
                text = {"ability_locale." .. global.default_abilities.ability_1},
                surface = lobby_surface,
                target = {x = -7, y = 7},
                color = {r = 1, g = 1, b = 1},
                alignment = "center",
                scale = 3,
                draw_on_ground = true,
            },
            ability_2 = rendering.draw_text{
                text = {"ability_locale." .. global.default_abilities.ability_2},
                surface = lobby_surface,
                target = {x = 0, y = 7},
                color = {r = 1, g = 1, b = 1},
                alignment = "center",
                scale = 3,
                draw_on_ground = true,
            },
            ability_3 = rendering.draw_text{
                text = {"ability_locale." .. global.default_abilities.ability_3},
                surface = lobby_surface,
                target = {x = 7, y = 7},
                color = {r = 1, g = 1, b = 1},
                alignment = "center",
                scale = 3,
                draw_on_ground = true,
            },
        },
        titles = {
            difficulty = rendering.draw_text{
                text = "Arena Difficulty",
                surface = lobby_surface,
                target = {x = 0, y = -14},
                color = {r = 1, g = 1, b = 1},
                alignment = "center",
                vertical_alignment = "middle",
                scale = 4,
                draw_on_ground = true,
            },
            starting_ability = rendering.draw_text{
                text = "Primary Ability",
                surface = lobby_surface,
                target = {x = 0, y = 14},
                color = {r = 1, g = 1, b = 1},
                alignment = "center",
                vertical_alignment = "middle",
                scale = 4,
                draw_on_ground = true,
            },
        }
    }
end

---@param lobby_surface LuaSurface
local function update_lobby_text(lobby_surface)
    local options = global.lobby_options
    local lobby_text = global.lobby_text
    local starting_abilities = lobby_text.starting_abilities
    for ability_number, render_id in pairs(starting_abilities) do
        if rendering.is_valid(render_id) then
            rendering.set_text(render_id, {"ability_locale." .. global.default_abilities[ability_number]})
        end
    end
end

---@param lobby_surface LuaSurface
local function initialize_lobby(lobby_surface)
    if not global.lobby_text then
        create_lobby_text(lobby_surface)
    end
    if not global.lobby_options then
        lobby_surface.always_day = true
        global.lobby_options = {
            difficulty = "easy",
            starting_ability = "ability_2",
        }
        update_lobby_tiles()
    end
end

return {
    reset_lobby_tiles = reset_lobby_tiles,
    update_lobby_tiles = update_lobby_tiles,
    create_lobby_text = create_lobby_text,
    initialize_lobby = initialize_lobby,
    update_lobby_text = update_lobby_text,
}
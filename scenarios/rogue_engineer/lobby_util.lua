
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

return {
    reset_lobby_tiles = reset_lobby_tiles,
    update_lobby_tiles = update_lobby_tiles,
}
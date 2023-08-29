
local constants = require("__asher_sky__/constants")
local difficulty_offsets = constants.difficulty_offsets
local difficulty_tile_names = constants.difficulty_tile_names
local ability_offsets = constants.ability_offsets
local walkway_tiles = constants.walkway_tiles
local top_right_offset = constants.top_right_offset
local bottom_right_offset = constants.bottom_right_offset
local bottom_left_offset = constants.bottom_left_offset
local top_left_offset = constants.top_left_offset
local raw_abilities_data = constants.ability_data
local general_util = require("general_util")
local random_table_key = general_util.random_table_key

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

local function create_lobby_text()
    local lobby_surface = game.surfaces.lobby
    global.lobby_text = {
        start_level = {
            top = rendering.draw_text {
                text = { "lobby_text_locale.enter" },
                surface = lobby_surface,
                target = { x = 21, y = -2 },
                color = { r = 1, g = 1, b = 1 },
                alignment = "center",
                scale = 3,
                draw_on_ground = true,
            },
            bottom = rendering.draw_text {
                text = { "lobby_text_locale.arena" },
                surface = lobby_surface,
                target = { x = 21, y = 0 },
                color = { r = 1, g = 1, b = 1 },
                alignment = "center",
                scale = 3,
                draw_on_ground = true,
            }
        },
        difficulties = {
            easy = rendering.draw_text {
                text = { "difficulty_locale.easy" },
                surface = lobby_surface,
                target = { x = -7, y = -9 },
                color = { r = 1, g = 1, b = 1 },
                alignment = "center",
                scale = 3,
                draw_on_ground = true,
            },
            normal = rendering.draw_text {
                text = { "difficulty_locale.normal" },
                surface = lobby_surface,
                target = { x = 0, y = -9 },
                color = { r = 1, g = 1, b = 1 },
                alignment = "center",
                scale = 3,
                draw_on_ground = true,
            },
            hard = rendering.draw_text {
                text = { "difficulty_locale.hard" },
                surface = lobby_surface,
                target = { x = 7, y = -9 },
                color = { r = 1, g = 1, b = 1 },
                alignment = "center",
                scale = 3,
                draw_on_ground = true,
            },
        },
        starting_abilities = {
            ability_1 = rendering.draw_text {
                text = { "ability_name." .. global.default_abilities.ability_1 },
                surface = lobby_surface,
                target = { x = -7, y = 7 },
                color = { r = 1, g = 1, b = 1 },
                alignment = "center",
                scale = 3,
                draw_on_ground = true,
            },
            ability_2 = rendering.draw_text {
                text = { "ability_name." .. global.default_abilities.ability_2 },
                surface = lobby_surface,
                target = { x = 0, y = 7 },
                color = { r = 1, g = 1, b = 1 },
                alignment = "center",
                scale = 3,
                draw_on_ground = true,
            },
            ability_3 = rendering.draw_text {
                text = { "ability_name." .. global.default_abilities.ability_3 },
                surface = lobby_surface,
                target = { x = 7, y = 7 },
                color = { r = 1, g = 1, b = 1 },
                alignment = "center",
                scale = 3,
                draw_on_ground = true,
            },
        },
        titles = {
            difficulty = rendering.draw_text {
                text = { "lobby_text_locale.arena_difficulty" },
                surface = lobby_surface,
                target = { x = 0, y = -14 },
                color = { r = 1, g = 1, b = 1 },
                alignment = "center",
                vertical_alignment = "middle",
                scale = 4,
                draw_on_ground = true,
            },
            starting_ability = rendering.draw_text {
                text = { "lobby_text_locale.primary_ability" },
                surface = lobby_surface,
                target = { x = 0, y = 14 },
                color = { r = 1, g = 1, b = 1 },
                alignment = "center",
                vertical_alignment = "middle",
                scale = 4,
                draw_on_ground = true,
            },
        }
    }
end

local function update_lobby_text()
    local lobby_text = global.lobby_text
    local starting_abilities = lobby_text.starting_abilities
    for ability_number, render_id in pairs(starting_abilities) do
        if rendering.is_valid(render_id) then
            rendering.set_text(render_id, { "ability_name." .. global.default_abilities[ability_number] })
        end
    end
end

local function initialize_lobby()
    local lobby_surface = game.surfaces.lobby
    if not global.lobby_text then
        create_lobby_text()
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

---@param ability_name string
---@param player LuaPlayer
local function set_ability(ability_name, player)
    global.player_data = global.player_data or {} --[[@type table<uint, player_data>]]
    local raw_data = raw_abilities_data[ability_name]
    global.player_data[player.index] = {
        level = 0,
        exp = 0,
        abilities = {
            [ability_name] = {
                name = ability_name,
                level = 1,
                cooldown = math.ceil(raw_data.default_cooldown),
                damage = raw_data.default_damage,
                radius = raw_data.default_radius,
                default_cooldown = raw_data.default_cooldown,
                default_damage = raw_data.default_damage,
                default_radius = raw_data.default_radius,
                damage_multiplier = raw_data.damage_multiplier,
                radius_multiplier = raw_data.radius_multiplier,
                cooldown_multiplier = raw_data.cooldown_multiplier,
                upgrade_order = raw_data.upgrade_order,
            }
        },
    }
    global.available_abilities = global.available_abilities or {}
    global.available_abilities[ability_name] = false
    for name, _ in pairs(global.available_abilities) do
        if name ~= ability_name then
            global.available_abilities[name] = true
        end
    end
end

---@param ability_number string
---@param player LuaPlayer
local function set_starting_ability(ability_number, player)
    local character = player.character
    if not character then return end
    local ratio = character.get_health_ratio()
    if ratio < 0.01 then
        character.health = player.character.prototype.max_health
        global.lobby_options.starting_ability = ability_number
        local ability_name = global.default_abilities[ability_number]
        set_ability(ability_name, player)
        update_lobby_tiles()
    else
        character.health = character.health - character.prototype.max_health / 90
    end
end

---@param difficulty string
---@param player LuaPlayer
local function set_difficulty(difficulty, player)
    local character = player.character
    if not character then return end
    local ratio = character.get_health_ratio()
    if ratio < 0.01 then
        character.health = player.character.prototype.max_health
        global.lobby_options.difficulty = difficulty
        update_lobby_tiles()
    else
        character.health = character.health - character.prototype.max_health / 90
    end
end

local function randomize_starting_abilities()
    -- local available_abilities = util.table.deepcopy(global.available_abilities)
    local available_abilities = util.table.deepcopy(global.available_starting_abilities)
    local default_abilities = global.default_abilities
    local starting_ability = global.lobby_options.starting_ability
    available_abilities[default_abilities[starting_ability]] = nil
    for ability_number, ability_name in pairs(default_abilities) do
        if not (ability_number == starting_ability) then
            local random_ability = random_table_key(available_abilities)
            global.default_abilities[ability_number] = random_ability
            available_abilities[random_ability] = nil
        end
    end
end

return {
    reset_lobby_tiles = reset_lobby_tiles,
    update_lobby_tiles = update_lobby_tiles,
    create_lobby_text = create_lobby_text,
    initialize_lobby = initialize_lobby,
    update_lobby_text = update_lobby_text,
    set_ability = set_ability,
    set_starting_ability = set_starting_ability,
    set_difficulty = set_difficulty,
    randomize_starting_abilities = randomize_starting_abilities,
}

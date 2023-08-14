

-- local debug_mode = true

local constants = require("__asher_sky__/constants")
local raw_abilities_data = constants.ability_data

---@param orientation float -- 0 to 1
---@param angle float -- 0 to 1, added to orientation
---@return float -- 0 to 1
local function rotate_orientation(orientation, angle)
    local new_orientation = orientation + angle
    if new_orientation > 1 then
        new_orientation = new_orientation - 1
    elseif new_orientation < 0 then
        new_orientation = new_orientation + 1
    end
    return new_orientation
end

local function on_init()
    global.player_data = {}
    global.damage_zones = {}
    global.healing_players = {}
    ---@enum available_abilities
    global.available_abilities = {
        burst = true,
        punch = true,
        cure = true,
        slash = true,
        rocket_launcher = true,
    }
end

---@param animation_name string
---@param ability_data active_ability_data
---@param player LuaPlayer
---@param position MapPosition?
local function draw_animation(animation_name, ability_data, player, position)
    if not animation_name then return end
    local raw_ability_data = raw_abilities_data[animation_name]
    local time_to_live = raw_ability_data.frame_count --[[@as uint]]
    local character = player.character
    local target = raw_ability_data.target == "character" and character or position or character.position
    local speed = 1 --defined in data.lua
    local scale = ability_data.radius / 2
    rendering.draw_animation{
        animation = animation_name,
        target = target,
        surface = player.surface,
        time_to_live = time_to_live,
        orientation = rotate_orientation(player.character.orientation, 0.25),
        x_scale = scale,
        y_scale = scale,
        animation_offset = -(game.tick * speed) % raw_ability_data.frame_count,
    }
end

---@param name string
---@param radius integer
---@param damage_per_tick number
---@param player LuaPlayer
---@param position MapPosition
---@param surface LuaSurface
---@param final_tick uint
local function create_damage_zone(name, radius, damage_per_tick, player, position, surface, final_tick)
    local damage_zone = {
        radius = radius,
        damage_per_tick = damage_per_tick,
        player = player,
        position = position,
        surface = surface,
        final_tick = final_tick,
    }
    local unique_id = name .. "-" .. player.index .. "-" .. game.tick .. "-" .. position.x .. "-" .. position.y
    global.damage_zones = global.damage_zones or {}
    global.damage_zones[unique_id] = damage_zone
end

---@param radius integer
---@param damage number
---@param position MapPosition
---@param surface LuaSurface
---@param player LuaPlayer
local function damage_enemies_in_radius(radius, damage, position, surface, player)
    local enemies = surface.find_entities_filtered{
        position = position,
        radius = radius,
        force = "enemy",
        type = "unit",
    }
    for _, enemy in pairs(enemies) do
        enemy.damage(damage, player.force, "impact", player.character)
    end
    if debug_mode then
        rendering.draw_circle{
            target = position,
            surface = surface,
            radius = radius,
            color = {r = 1, g = 0, b = 0},
            filled = false,
            time_to_live = 2,
        }
    end
end

local aoe_damage_modifier = 20

---@param ability_data active_ability_data
---@param player LuaPlayer
local function activate_burst_damage(ability_data, player)
    local position = player.position
    local surface = player.surface
    local radius = ability_data.radius
    local damage_per_tick = ability_data.damage / aoe_damage_modifier
    local final_tick = game.tick + (raw_abilities_data.burst.frame_count * 1.25)
    create_damage_zone("burst", radius, damage_per_tick, player, position, surface, final_tick)
end

---@param ability_data active_ability_data
---@param player LuaPlayer
local function activate_punch_damage(ability_data, player)
    local radius = ability_data.radius
    local damage = ability_data.damage
    local position = player.position
    local surface = player.surface
    damage_enemies_in_radius(radius, damage, position, surface, player)
    local damage_per_tick = damage / aoe_damage_modifier
    local final_tick = game.tick + (raw_abilities_data.punch.frame_count * 0.75)
    create_damage_zone("punch", radius, damage_per_tick, player, position, surface, final_tick)
end

---@param ability_data active_ability_data
---@param player LuaPlayer
local function activate_cure_damage(ability_data, player)
    global.healing_players = global.healing_players or {}
    global.healing_players[player.index] = {
        player = player,
        damage = ability_data.damage,
        final_tick = game.tick + (raw_abilities_data.cure.frame_count * 1.25),
    }
end

local function activate_slash_damage(ability_data, player)
    local radius = ability_data.radius
    local damage = ability_data.damage
    local position = player.position
    local surface = player.surface
    damage_enemies_in_radius(radius, damage, position, surface, player)
end

---@param ability_data active_ability_data
---@param player LuaPlayer
local function activate_rocket_launcher(ability_data, player)
    local surface = player.surface
    local enemy = surface.find_nearest_enemy{
        position = player.position,
        max_distance = ability_data.radius,
        force = player.force,
    }
    if not enemy then return end
    local rocket = surface.create_entity{
        name = "rocket",
        position = player.position,
        direction = player.character.direction,
        force = player.force,
        target = enemy,
        source = player.character,
        speed = 1/25,
        max_range = ability_data.radius * 1.5,
        player = player,
        character = player.character,
    }
end

local damage_functions = {
    burst = activate_burst_damage,
    punch = activate_punch_damage,
    cure = activate_cure_damage,
    slash = activate_slash_damage,
    rocket_launcher = activate_rocket_launcher,
}

local animation_functions = {
    burst = draw_animation,
    punch = draw_animation,
    cure = draw_animation,
    slash = draw_animation,
    -- rocket_launcher = function ()
    --     return
    -- end,
}

local function draw_animations(ability_name, ability_data, player)
    local animate = animation_functions and animation_functions[ability_name]
    if animate then
        animate(ability_name, ability_data, player)
    end
end

---@param ability_name string
---@param ability_data active_ability_data
---@param player LuaPlayer
local function damage_enemies(ability_name, ability_data, player)
    local activate_damage = damage_functions and damage_functions[ability_name]
    if activate_damage then
        activate_damage(ability_data, player)
    end
end

---@param ability_name string
---@param ability_data active_ability_data
---@param player LuaPlayer
local function activate_ability(ability_name, ability_data, player)
    draw_animations(ability_name, ability_data, player)
    damage_enemies(ability_name, ability_data, player)
end

---@param abilities table<string, active_ability_data>
---@param player LuaPlayer
local function upgrade_random_ability(abilities, player)
    local ability_names = {}
    for ability_name, ability_data in pairs(abilities) do
        if ability_data.level < 10 then
            table.insert(ability_names, ability_name)
        end
    end
    local ability_name = ability_names[math.random(#ability_names)]
    local ability_data = abilities[ability_name]
    local upgrade_type = math.random(1, 4)
    if upgrade_type == 1 then
        ability_data.cooldown = math.ceil(ability_data.cooldown - ability_data.cooldown * 0.125)
        game.print("Level up! " .. ability_name .. " cooldown is now " .. ability_data.cooldown .. ".")
    elseif upgrade_type == 2 then
        ability_data.radius = ability_data.radius + 1
        game.print("Level up! " .. ability_name .. " radius is now " .. ability_data.radius .. ".")
    elseif upgrade_type == 3 then
        ability_data.damage = ability_data.damage * ability_data.damage_multiplier
        game.print("Level up! " .. ability_name .. " damage is now " .. ability_data.damage .. ".")
    elseif upgrade_type == 4 then
        local character_running_speed_modifier = player.character_running_speed_modifier
        player.character_running_speed_modifier = character_running_speed_modifier + 0.25
        game.print("Level up! " .. "player" .. " speed is now " .. character_running_speed_modifier + 0.25 .. ".")
    end
end

---@param ability_name string
---@param player LuaPlayer
local function unlock_named_ability(ability_name, player)
    local player_data = global.player_data[player.index]
    if not player_data.abilities[ability_name] then
        player_data.abilities[ability_name] = {
            level = 1,
            cooldown = math.ceil(raw_abilities_data[ability_name].default_cooldown),
            damage = raw_abilities_data[ability_name].default_damage,
            radius = raw_abilities_data[ability_name].default_radius,
            damage_multiplier = raw_abilities_data[ability_name].damage_multiplier,
        }
        game.print("New ability unlocked! " .. ability_name .. " is now level 1.")
        global.available_abilities[ability_name] = false
    end
end

---@param player LuaPlayer
local function unlock_random_ability(player)
    local ability_names = {}
    for name, available in pairs(global.available_abilities) do
        if available then
            table.insert(ability_names, name)
        end
    end
    if #ability_names == 0 then
        game.print("Achievement Get! All abilities unlocked")
        return
    end
    local ability_name = ability_names[math.random(#ability_names)]
    unlock_named_ability(ability_name, player)
end

---@param player LuaPlayer
local function update_kill_counter(player)
    if not player.character then return end
    local player_index = player.index
    global.kill_counters = global.kill_counters or {}
    global.kill_counters[player_index] = global.kill_counters[player_index] or {
        render_id = rendering.draw_text{
            text = "Kills: 0",
            surface = player.surface,
            target = player.character,
            target_offset = { x = 0, y = 1 },
            color = { r = 1, g = 1, b = 1 },
            scale = 1.5,
            alignment = "center",
        },
        kill_count = 0,
    }
    local kill_counter = global.kill_counters[player_index]
    kill_counter.kill_count = kill_counter.kill_count + 1
    if not rendering.is_valid(kill_counter.render_id) then
        kill_counter.render_id = rendering.draw_text{
            text = "Kills: 0",
            surface = player.surface,
            target = player.character,
            target_offset = { x = 0, y = 1 },
            color = { r = 1, g = 1, b = 1 },
            scale = 1.5,
            alignment = "center",
        }
    end
    rendering.set_text(kill_counter.render_id, "Kills: " .. kill_counter.kill_count)
end

local function get_position_on_circumference(center, radius, angle)
    local x = center.x + radius * math.cos(angle)
    local y = center.y + radius * math.sin(angle)
    return { x = x, y = y }
end

local function get_random_position_on_circumference(center, radius)
    local angle = math.random() * 2 * math.pi
    return get_position_on_circumference(center, radius, angle)
end

---@param surface LuaSurface
---@param position MapPosition
---@param name string
---@param player LuaPlayer?
local function spawn_new_enemy(surface, position, name, player)
    local enemy = surface.create_entity{
        name = name,
        position = position,
        force = game.forces.enemy,
        target = player and player.character or nil,
    }
end

---@param event EventData.on_entity_died
local function on_entity_died(event)
    local entity = event.entity
    if not (entity.surface.name == "arena") then return end
    local cause = event.cause
    local player = cause and cause.type == "character" and cause.player
    if player then
        local player_data = global.player_data[player.index]
        player_data.exp = player_data.exp + 1
        if player_data.exp >= 10 * player_data.level then
            player_data.exp = 0
            player_data.level = player_data.level + 1
            upgrade_random_ability(player_data.abilities, player)
            local shimmer_data = { radius = 2, level = 1, cooldown = 0, damage = 0 }
            draw_animation("shimmer", shimmer_data, player)
            if player_data.level % 5 == 0 then
                unlock_random_ability(player)
            end
        end
        update_kill_counter(player)
        local radius = math.random(25, 50)
        local position = get_random_position_on_circumference(player.position, radius)
        local enemy_name = entity.name
        spawn_new_enemy(player.surface, position, enemy_name, player)
    end
end

local difficulty_offsets = {
    easy = { x = -7, y = -8 },
    normal = { x = 0, y = -8 },
    hard = { x = 7, y = -8 },
}
local ability_offsets = {
    burst = { x = -7, y = 8 },
    punch = { x = 0, y = 8 },
    rocket_launcher = { x = 7, y = 8 },
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
    burst = {
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
    punch = {
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
    rocket_launcher = {
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

---@param ability_name string
---@param player LuaPlayer
local function set_ability(ability_name, player)
    global.player_data = global.player_data or {}
    global.player_data[player.index] = {
        level = 0,
        exp = 0,
        abilities = {
            [ability_name] = {
                level = 1,
                cooldown = math.ceil(raw_abilities_data[ability_name].default_cooldown),
                damage = raw_abilities_data[ability_name].default_damage,
                radius = raw_abilities_data[ability_name].default_radius,
                damage_multiplier = raw_abilities_data[ability_name].damage_multiplier,
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

---@param ability_name string
---@param player LuaPlayer
local function set_starting_ability(ability_name, player)
    local character = player.character
    if not character then return end
    local ratio = character.get_health_ratio()
    if ratio < 0.01 then
        character.health = player.character.prototype.max_health
        global.lobby_options.starting_ability = ability_name
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

---@param player LuaPlayer
local function reset_health(player)
    local character = player.character
    if not character then return end
    character.health = character.prototype.max_health
end

local function initialize_player_data(player)
    local starting_ability = global.lobby_options.starting_ability
    set_ability(starting_ability, player)
end

local function create_arena_surface()
    local map_gen_settings = {
        terrain_segmentation = 3,
        water = 1/4,
        -- autoplace_controls = {
        --     ["coal"] = {frequency = 0, size = 0, richness = 0},
        --     ["stone"] = {frequency = 0, size = 0, richness = 0},
        --     ["copper-ore"] = {frequency = 0, size = 0, richness = 0},
        --     ["iron-ore"] = {frequency = 0, size = 0, richness = 0},
        --     ["uranium-ore"] = {frequency = 0, size = 0, richness = 0},
        --     ["crude-oil"] = {frequency = 0, size = 0, richness = 0},
        --     ["trees"] = {frequency = 0, size = 0, richness = 0},
        --     ["enemy-base"] = {frequency = 0, size = 0, richness = 0},
        -- },
        width = 5000,
        height = 5000,
        seed = math.random(1, 1000000),
        starting_area = 1/4,
        starting_points = {{x = 0, y = 0}},
        peaceful_mode = false,
    }
    if game.surfaces.arena then
        game.delete_surface(game.surfaces.arena)
    end
    game.create_surface("arena", map_gen_settings)
end

local function enter_arena()
    local all_players_ready = true
    local players = game.connected_players
    for _, player in pairs(players) do
        local x = player.position.x
        local y = player.position.y
        if not ((y < 3 and y > -3) and (x < 24 and x > 18)) then
            all_players_ready = false
        end
    end
    if all_players_ready then
        local actually_ready = false
        for _, player in pairs(players) do
            local character = player.character
            if not character then return end
            local ratio = character.get_health_ratio()
            if ratio < 0.01 then
                character.health = player.character.prototype.max_health
                actually_ready = true
            else
                character.health = character.health - character.prototype.max_health / 180
            end
        end
        if actually_ready then
            create_arena_surface()
            global.game_state = "arena"
            for _, player in pairs(players) do
                player.teleport({x = 0, y = 0}, "arena")
            end
        end
    end
end

---@param event EventData.on_tick
local function on_tick(event)

    if not script.level and script.level.mod_name == "asher_sky" then return end
    global.game_state = global.game_state or "lobby"

    -- lobby mode --
    if global.game_state == "lobby" then

        local lobby_surface = game.surfaces.lobby
        if not global.lobby_text then
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
                    burst = rendering.draw_text{
                        text = "Burst",
                        surface = lobby_surface,
                        target = {x = -7, y = 7},
                        color = {r = 1, g = 1, b = 1},
                        alignment = "center",
                        scale = 3,
                        draw_on_ground = true,
                    },
                    punch = rendering.draw_text{
                        text = "Punch",
                        surface = lobby_surface,
                        target = {x = 0, y = 7},
                        color = {r = 1, g = 1, b = 1},
                        alignment = "center",
                        scale = 3,
                        draw_on_ground = true,
                    },
                    rocket_launcher = rendering.draw_text{
                        text = "Rocket",
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
        if not global.lobby_options then
            lobby_surface.always_day = true
            global.lobby_options = {
                difficulty = "easy",
                starting_ability = "punch",
            }
            update_lobby_tiles()
        end
        for _, player in pairs(game.connected_players) do
            local position = player.position
            if not (player.surface_index == lobby_surface.index) then
                player.teleport(position, lobby_surface)
            end
            if not player.character then return end
            if player.character_running_speed_modifier < 0.33 then
                player.character_running_speed_modifier = 0.33
            end
            local lobby_options = global.lobby_options
            if not global.player_data[player.index] then
                initialize_player_data(player)
            end
            local x = position.x
            local y = position.y
            if y < -6 and y > -10 then
                if x < -4 and x > -10 then
                    if not (lobby_options.difficulty == "easy") then
                        set_difficulty("easy", player)
                    end
                elseif x < 3 and x > -3 then
                    if not (lobby_options.difficulty == "normal") then
                        set_difficulty("normal", player)
                    end
                elseif x < 10 and x > 4 then
                    if not (lobby_options.difficulty == "hard") then
                        set_difficulty("hard", player)
                    end
                else
                    reset_health(player)
                end
            elseif y < 10 and y > 6 then
                if x < -4 and x > -10 then
                    if not (lobby_options.starting_ability == "burst") then
                        set_starting_ability("burst", player)
                    end
                elseif x < 3 and x > -3 then
                    if not (lobby_options.starting_ability == "punch") then
                        set_starting_ability("punch", player)
                    end
                elseif x < 10 and x > 4 then
                    if not (lobby_options.starting_ability == "rocket_launcher") then
                        set_starting_ability("rocket_launcher", player)
                    end
                else
                    reset_health(player)
                end
            elseif y < 3 and y > -3 then
                if x < 24 and x > 18 then
                    initialize_player_data(player)
                    enter_arena()
                else
                    reset_health(player)
                end
            else
                reset_health(player)
            end
        end
        if game.tick % (60 * 7) == 0 then
            local enemies = lobby_surface.find_entities_filtered{type = "unit", force = "enemy"}
            if #enemies == 0 then
                local positions = {
                    {x = 12, y = 12},
                    {x = -12, y = 12},
                    {x = 12, y = -12},
                    {x = -12, y = -12},
                }
                local index = math.random(1, #positions)
                local position = positions[index]
                spawn_new_enemy(lobby_surface, position, "small-biter")
            end
        end
    end

    -- arena mode --

    for _, player in pairs(game.connected_players) do
        if not player.character then return end
        global.player_data[player.index] = global.player_data[player.index] or initialize_player_data(player)
        local player_data = global.player_data[player.index]
        for ability_name, ability_data in pairs(player_data.abilities) do
            if event.tick % ability_data.cooldown == 0 then
                activate_ability(ability_name, ability_data, player)
            end
        end
    end
    for id, damage_zone in pairs(global.damage_zones) do
        damage_enemies_in_radius(damage_zone.radius, damage_zone.damage_per_tick, damage_zone.position, damage_zone.surface, damage_zone.player)
        if damage_zone.final_tick <= event.tick then
            global.damage_zones[id] = nil
        end
    end
    for id, healing_player in pairs(global.healing_players) do
        local player = healing_player.player
        if player.character then
            player.character.damage(healing_player.damage, player.force, "impact", player.character)
        end
        if healing_player.final_tick <= event.tick then
            global.healing_players[id] = nil
        end
    end

    if global.game_state == "arena" then
        local difficulties = {
            easy = 2,
            normal = 1,
            hard = 0.5,
        }
        local balance = difficulties[global.lobby_options.difficulty] * 60
        if game.tick % balance == 0 then
            for _, player in pairs(game.connected_players) do
                local radius = math.random(25, 50)
                local position = get_random_position_on_circumference(player.position, radius)
                local enemy_name = "small-biter"
                spawn_new_enemy(player.surface, position, enemy_name, player)
            end
        end
    end
end

script.on_init(on_init)
script.on_event(defines.events.on_tick, on_tick)
script.on_event(defines.events.on_entity_died, on_entity_died)

---@class active_ability_data
---@field level number
---@field cooldown number
---@field damage number
---@field radius number
---@field damage_multiplier number
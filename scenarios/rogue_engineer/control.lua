
local debug_mode = false

require("util")
local constants = require("__asher_sky__/constants")
local tile_tiers_by_name = constants.tile_tiers_by_name
local tile_tiers_by_order = constants.tile_tiers_by_order
local difficulty_tile_names = constants.difficulty_tile_names
local difficulty_offsets = constants.difficulty_offsets
local ability_offsets = constants.ability_offsets
local top_right_offset = constants.top_right_offset
local bottom_right_offset = constants.bottom_right_offset
local bottom_left_offset = constants.bottom_left_offset
local top_left_offset = constants.top_left_offset
local walkway_tiles = constants.walkway_tiles
local raw_abilities_data = constants.ability_data

local aoe_damage_modifier = 20

local lobby_util = require("lobby_util")
local update_lobby_tiles = lobby_util.update_lobby_tiles
local reset_lobby_tiles = lobby_util.reset_lobby_tiles
local create_lobby_text = lobby_util.create_lobby_text
local update_lobby_text = lobby_util.update_lobby_text
local initialize_lobby = lobby_util.initialize_lobby
local set_ability = lobby_util.set_ability
local set_difficulty = lobby_util.set_difficulty
local set_starting_ability = lobby_util.set_starting_ability
local randomize_starting_abilities = lobby_util.randomize_starting_abilities

local statistics_util = require("statistics_util")
local update_statistics = statistics_util.update_statistics
local initialize_statistics = statistics_util.initialize_statistics
local new_attempt_stats_reset = statistics_util.new_attempt_stats_reset
local initialize_player_statistics = statistics_util.initialize_player_statistics
local calculate_kills_per_minute = statistics_util.calculate_kills_per_minute
local update_kpm_statistics = statistics_util.update_kpm_statistics

local general_util = require("general_util")
local rotate_orientation = general_util.rotate_orientation
local get_position_on_circumference = general_util.get_position_on_circumference
local get_random_position_on_circumference = general_util.get_random_position_on_circumference
local random_table_value = general_util.random_table_value
local random_table_key = general_util.random_table_key
local offset_vector = general_util.offset_vector
local direction_to_angle = general_util.direction_to_angle
local opposite_direction = general_util.opposite_direction
local normalize_degrees = general_util.normalize_degrees
local format_time = general_util.format_time
local valid_player_character = general_util.valid_player_character
local degrees_to_radians = general_util.degrees_to_radians
local arena_ticks_remaining = general_util.arena_ticks_remaining
local arena_ticks_elapsed = general_util.arena_ticks_elapsed
local distance = general_util.distance

local gooey_util = require("gooey_util")
local create_arena_gui = gooey_util.create_arena_gui
local update_arena_gui_kills = gooey_util.update_arena_gui_kills
local update_arena_gui_time_remaining = gooey_util.update_arena_gui_time_remaining
local update_arena_gui_lives_remaining = gooey_util.update_arena_gui_lives_remaining
local update_arena_gui_kills_per_minute = gooey_util.update_arena_gui_kills_per_minute
local update_arena_gui = gooey_util.update_arena_gui
local destroy_arena_gui = gooey_util.destroy_arena_gui
local add_arena_gui_ability_info = gooey_util.add_arena_gui_ability_info
local update_arena_gui_ability_info = gooey_util.update_arena_gui_ability_info

local luarendering_util = require("luarendering_util")
local draw_animation = luarendering_util.draw_animation
local draw_text = luarendering_util.draw_text
local draw_upgrade_text = luarendering_util.draw_upgrade_text
local draw_announcement_text = luarendering_util.draw_announcement_text

local function on_init()
    global.player_data = {}
    global.damage_zones = {}
    global.healing_players = {}
    ---@enum available_abilities
    global.available_abilities = {
        burst = true,
        punch = true,
        -- cure = true,
        slash = true,
        rocket_launcher = true,
        pavement = true,
        beam_blast = true,
        discharge_defender = true,
        destroyer = true,
        distractor = true,
        defender = true,
        landmine = true,
        poison_capsule = true,
        slowdown_capsule = true,
        gun_turret = true,
        shotgun = true,
        barrier = true,
        purifying_light = true,
        crystal_blossom = true,
    }
    global.available_starting_abilities = {
        burst = true,
        punch = true,
        -- cure = true,
        slash = true,
        rocket_launcher = true,
        -- pavement = true,
        beam_blast = true,
        discharge_defender = true,
        destroyer = true,
        distractor = true,
        defender = true,
        -- landmine = true,
        poison_capsule = true,
        -- slowdown_capsule = true,
        -- gun_turret = true,
        shotgun = true,
        barrier = true,
        purifying_light = true,
        crystal_blossom = true,
    }
    global.default_abilities = {
        ability_1 = "beam_blast",
        ability_2 = "crystal_blossom",
        ability_3 = "rocket_launcher",
    }
    global.statistics = {}
    global.flamethrower_targets = {}
    global.burn_zones = {}
    global.poison_zones = {}
    global.laser_beam_targets = {}
    global.game_length = 60 * 60 * 15
    global.game_duration = {
        easy = 60 * 60 * 7,
        normal = 60 * 60 * 11,
        hard = 60 * 60 * 15,
    }
end

---@param entities LuaEntity[]
---@return LuaEntity[]
local function filter_valid_entities(entities)
    for id, entity in pairs(entities) do
        if not entity.valid then
            entities[id] = nil
        end
    end
    return entities
end

local function register_burn_zone(ability_name, position, player, final_tick)
    local burn_zone = {
        position = position,
        player = player,
        surface = player.surface,
        final_tick = final_tick,
    }
    local unique_id = "burn-zone-" .. "-" .. ability_name .. "-" .. player.index .. "-" .. game.tick .. "-" .. position.x .. "-" .. position.y
    global.burn_zones = global.burn_zones or {}
    global.burn_zones[unique_id] = burn_zone
end

local function create_flamethrower_target(ability_name, position, player, final_tick)
    local flamethrower_target = {
        position = position,
        player = player,
        surface = player.surface,
        final_tick = final_tick,
    }
    local unique_id = ability_name .. "-" .. player.index .. "-" .. game.tick .. "-" .. position.x .. "-" .. position.y
    global.flamethrower_targets = global.flamethrower_targets or {}
    global.flamethrower_targets[unique_id] = flamethrower_target
    local burning_until = game.tick + 60 * 45
    register_burn_zone(ability_name, position, player, burning_until)
end

---@param name string
---@param radius integer
---@param damage_per_tick number
---@param player LuaPlayer
---@param position MapPosition
---@param surface LuaSurface
---@param final_tick uint
local function register_damage_zone(name, radius, damage_per_tick, player, position, surface, final_tick)
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

---@param ability_data active_ability_data
---@param target LuaEntity
---@param player LuaPlayer
---@param final_tick uint
local function register_laser_beam_target(ability_data, target, player, final_tick, primary_target)
    local laser_beam_target = {
        ability_data = ability_data,
        target = target,
        player = player,
        surface = player.surface,
        final_tick = final_tick,
        primary_target = primary_target,
    }
    local unique_id = ability_data.name .. "-" .. player.index .. "-" .. game.tick .. "-" .. target.unit_number
    global.laser_beam_targets = global.laser_beam_targets or {}
    global.laser_beam_targets[unique_id] = laser_beam_target
end

---@param surface LuaSurface
---@param position MapPosition
---@param source MapPosition|LuaEntity
---@param target MapPosition|LuaEntity
---@param force ForceIdentification
local function create_laser_beam(surface, position, source, target, force)
    local beam_name = "no-damage-laser-beam"
    ---@diagnostic disable: missing-fields
    local beam = surface.create_entity{
        name = beam_name,
        position = position,
        force = force,
        target = target,
        source = source,
        speed = 1/10,
        max_range = 100,
        duration = 33,
    }
    ---@diagnostic enable: missing-fields
end

---@param ability_name string
---@param position MapPosition
---@param player LuaPlayer
---@param final_tick uint
local function register_poison_zone(ability_name, position, player, final_tick)
    local poison_zone = {
        position = position,
        player = player,
        surface = player.surface,
        final_tick = final_tick,
    }
    local unique_id = "poison-zone-" .. "-" .. ability_name .. "-" .. player.index .. "-" .. game.tick .. "-" .. position.x .. "-" .. position.y
    global.poison_zones = global.poison_zones or {}
    global.poison_zones[unique_id] = poison_zone
end

---@param turret LuaEntity
---@param ability_data active_ability_data
local function refill_infividual_turret_ammo(turret, ability_data)
    local inventory = turret.get_inventory(defines.inventory.turret_ammo)
    local ammo_name =(( ability_data.level > 12 ) and "uranium-rounds-magazine") or (( ability_data.level > 6 ) and "piercing-rounds-magazine") or "firearm-magazine"
    local ammo_items = { name = ammo_name, count = math.max(2, ability_data.level / 2)}
    if inventory and inventory.can_insert(ammo_items) then
        inventory.insert(ammo_items)
        local localised_name = {"item-name." .. ammo_name}
        ---@diagnostic disable: missing-fields
        turret.surface.create_entity{
            name = "flying-text",
            position = turret.position,
            text = {"", "+", ammo_items.count, " ", localised_name},
            color = {r = 1, g = 1, b = 1},
        }
        ---@diagnostic enable: missing-fields
    end
end

---@param ability_data active_ability_data
---@param character LuaEntity
local function refill_existing_turrets(ability_data, character)
    local animation_name = "buff"
    local radius = ability_data.radius
    local surface = character.surface
    local force = character.force
    local position = character.position
    local nearby_turrets = surface.find_entities_filtered{
        position = position,
        radius = radius,
        force = force,
        type = "ammo-turret",
    }
    if not nearby_turrets then return end
    nearby_turrets = filter_valid_entities(nearby_turrets)
    for _, turret in pairs(nearby_turrets) do
        refill_infividual_turret_ammo(turret, ability_data)
        draw_animation(animation_name, turret, surface, 0, 2)
    end
end

---@param player LuaPlayer
---@param target_position MapPosition
local function activate_flamethrower(player, target_position)
    local surface = player.surface
    ---@diagnostic disable: missing-fields
    local stream = surface.create_entity{
        name = "handheld-flamethrower-fire-stream",
        position = player.position,
        force = player.force,
        target = target_position,
        source = player.character,
        character = player.character,
        player = player,
    }
    ---@diagnostic enable: missing-fields
end

---@param position MapPosition
---@param radius integer
---@param force ForceIdentification
---@param surface LuaSurface
---@return LuaEntity?
local function find_nearest_enemy(position, radius, force, surface)
    local enemy = surface.find_nearest_enemy{
        position = position,
        max_distance = radius,
        force = force,
    }
    if enemy and enemy.valid then
        return enemy
    end
end

---@param surface LuaSurface
---@param position MapPosition
---@param radius integer
---@return LuaEntity[]
local function get_enemies_in_radius(surface, position, radius)
    local enemies = surface.find_entities_filtered{
        position = position,
        radius = radius,
        force = "enemy",
        -- type = {"unit", "turret", "unit-spawner"},
        type = {"unit", "turret"},
    }
    enemies = filter_valid_entities(enemies)
    return enemies
end

---@param radius integer
---@param damage float
---@param position MapPosition
---@param surface LuaSurface
---@param player LuaPlayer
local function damage_enemies_in_radius(radius, damage, position, surface, player)
    local character = player.character
    if not character then return end
    local enemies = get_enemies_in_radius(surface, position, radius)
    for _, enemy in pairs(enemies) do
        if enemy.valid then
            enemy.damage(damage, player.force, "impact", character)
        end
    end
end

---@param ability_data active_ability_data
---@param player LuaPlayer
---@param character LuaEntity
local function activate_burst_ability(ability_data, player, character)
    local animation_name = ability_data.name
    local radius = ability_data.radius
    local damage = ability_data.damage
    local damage_per_tick = damage / aoe_damage_modifier
    local position = character.position
    local surface = character.surface
    local orientation = character.orientation
    local frame_count = raw_abilities_data[animation_name].frame_count
    local final_tick = game.tick + frame_count
    draw_animation(animation_name, position, surface, orientation, radius, frame_count)
    register_damage_zone(animation_name, radius, damage_per_tick, player, position, surface, final_tick)
end

---@param ability_data active_ability_data
---@param player LuaPlayer
---@param character LuaEntity
local function activate_punch_ability(ability_data, player, character)
    local animation_name = ability_data.name
    local radius = ability_data.radius
    local damage = ability_data.damage
    local damage_per_tick = damage / aoe_damage_modifier
    local position = character.position
    local surface = character.surface
    local orientation = character.orientation
    local frame_count = raw_abilities_data[animation_name].frame_count
    local final_tick = game.tick + 25
    draw_animation(animation_name, position, surface, orientation, radius, frame_count)
    damage_enemies_in_radius(radius, damage, position, surface, player)
    register_damage_zone(animation_name, radius, damage_per_tick, player, position, surface, final_tick)
end

---@param ability_data active_ability_data
---@param player LuaPlayer
---@param character LuaEntity
local function activate_cure_ability(ability_data, player, character)
    local animation_name = ability_data.name
    local radius = ability_data.radius
    local damage = ability_data.damage
    local damage_per_tick = damage / aoe_damage_modifier
    local position = character.position
    local surface = character.surface
    local orientation = character.orientation
    local frame_count = raw_abilities_data[animation_name].frame_count
    local final_tick = game.tick + frame_count
    draw_animation(animation_name, character, surface, orientation, radius, frame_count)
    global.healing_players = global.healing_players or {}
    global.healing_players[player.index] = {
        player = player,
        damage = damage,
        final_tick = final_tick,
    }
end

---@param ability_data active_ability_data
---@param player LuaPlayer
---@param character LuaEntity
local function activate_slash_ability(ability_data, player, character)
    local animation_name = ability_data.name
    local radius = ability_data.radius
    local damage = ability_data.damage
    local position = character.position
    local surface = character.surface
    local orientation = character.orientation - 45/360
    local frame_count = raw_abilities_data[animation_name].frame_count
    local final_tick = game.tick + frame_count
    draw_animation(animation_name, position, surface, orientation, radius, frame_count)
    damage_enemies_in_radius(radius, damage, position, surface, player)
end

---@param ability_data active_ability_data
---@param player LuaPlayer
---@param character LuaEntity
local function activate_rocket_launcher_ability(ability_data, player, character)
    local animation_name = "debuff"
    local radius = ability_data.radius
    local position = character.position
    local surface = character.surface
    local orientation = 0
    local frame_count = raw_abilities_data[animation_name].frame_count
    local enemy = find_nearest_enemy(position, radius, player.force, surface)
    if not enemy then return end
    ---@diagnostic disable: missing-fields
    local rocket = surface.create_entity{
        name = "rocket",
        position = position,
        force = player.force,
        target = enemy,
        source = character,
        speed = 1/10,
        max_range = radius * 20,
        player = player,
    }
    ---@diagnostic enable: missing-fields
    draw_animation(animation_name, enemy, surface, orientation, 0.8, frame_count, "radius-visualization")
end

---@param ability_data active_ability_data
---@param player LuaPlayer
---@param character LuaEntity
local function activate_pavement_ability(ability_data, player, character)
    local name = ability_data.name
    local radius = ability_data.radius
    local position = character.position
    local surface = character.surface
    local tile = surface.get_tile(position.x, position.y)
    local tile_name = tile.name
    local tile_tier = tile_tiers_by_name[tile_name] or 0
    local normalized_tile_tier = math.min(math.max(ability_data.level - 5, 0), tile_tier)
    local next_tile_name = tile_tiers_by_order[normalized_tile_tier + 1]
    if not next_tile_name then return end
    local tiles = {
        { name = next_tile_name, position = { x = position.x, y = position.y } }
    }
    if radius > 1 then
        local edge = radius - 1
        for x = -edge, edge do
            for y = -edge, edge do
                if x ~= 0 or y ~= 0 then
                    table.insert(tiles, { name = next_tile_name, position = { x = position.x + x, y = position.y + y } })
                end
            end
        end
    end
    surface.set_tiles(tiles)
end

---@param ability_data active_ability_data
---@param player LuaPlayer
---@param character LuaEntity
local function activate_beam_blast_ability(ability_data, player, character)
    local surface = character.surface
    local player_position = character.position
    local player_force = character.force
    local radius = ability_data.radius
    local primary_target = find_nearest_enemy(player_position, radius * 2, player_force, surface)
    if not primary_target then return end
    local primary_target_id = primary_target.unit_number
    local primary_target_position = primary_target.position
    local nearby_enemies = get_enemies_in_radius(surface, primary_target.position, radius / 1.5)
    create_laser_beam(surface, player_position, character, primary_target, player_force)
    register_laser_beam_target(ability_data, primary_target, player, game.tick + 33, primary_target)
    for _, secondary_target in pairs(nearby_enemies) do
        if secondary_target.valid then
            if secondary_target.unit_number ~= primary_target_id then
                create_laser_beam(surface, primary_target_position, primary_target, secondary_target, player_force)
                register_laser_beam_target(ability_data, secondary_target, player, game.tick + 33, primary_target)
            end
        end
    end
end

---@param ability_data active_ability_data
---@param player LuaPlayer
---@param character LuaEntity
local function activate_discharge_defender_ability(ability_data, player, character)
    local animation_name = "buff"
    local surface = character.surface
    local position = character.position
    local force = character.force
    local radius = ability_data.radius
    ---@diagnostic disable: missing-fields
    local discharge_defender = surface.create_entity{
        name = "discharge-defender",
        position = position,
        direction = character.direction,
        force = force,
        -- target = enemy,
        target = character,
        source = character,
        speed = 1/10,
        max_range = radius * 20,
        player = player,
    }
    ---@diagnostic enable: missing-fields
    if discharge_defender then
        draw_animation(animation_name, discharge_defender, surface)
    end
end

---@param ability_data active_ability_data
---@param player LuaPlayer
---@param character LuaEntity
local function activate_destroyer_capsule_ability(ability_data, player, character)
    local animation_name = "buff"
    local surface = character.surface
    local position = character.position
    local force = character.force
    local radius = ability_data.radius
    ---@diagnostic disable: missing-fields
    local destroyer = surface.create_entity{
        name = "destroyer",
        position = position,
        direction = character.direction,
        force = force,
        -- target = enemy,
        target = character,
        source = character,
        speed = 1/10,
        max_range = radius * 20,
        player = player,
    }
    ---@diagnostic enable: missing-fields
    if destroyer then
        draw_animation(animation_name, destroyer, surface)
    end
end

---@param ability_data active_ability_data
---@param player LuaPlayer
---@param character LuaEntity
local function activate_distractor_capsule_ability(ability_data, player, character)
    local animation_name = "buff"
    local surface = character.surface
    local character_position = character.position
    local force = character.force
    local radius = ability_data.radius
    for i = -2, 2 do
        local angle = direction_to_angle(player.character.direction)
        local offset_angle = angle + degrees_to_radians(i * 30)
        local position = get_position_on_circumference(character_position, radius, offset_angle)
        ---@diagnostic disable: missing-fields
        local distractor = surface.create_entity{
            name = "distractor",
            position = position,
            direction = character.direction,
            force = force,
            target = character,
            source = character,
            speed = 1/10,
            max_range = radius * 20,
            player = player,
        }
        ---@diagnostic enable: missing-fields
        if distractor then
            draw_animation(animation_name, distractor, surface)
        end
    end
end

---@param ability_data active_ability_data
---@param player LuaPlayer
---@param character LuaEntity
local function activate_defender_capsule_ability(ability_data, player, character)
    local animation_name = "buff"
    local surface = character.surface
    local position = character.position
    local force = character.force
    local radius = ability_data.radius
    ---@diagnostic disable: missing-fields
    local defender = surface.create_entity{
        name = "defender",
        position = position,
        direction = character.direction,
        force = force,
        target = character,
        source = character,
        speed = 1/10,
        max_range = radius * 20,
        player = player,
    }
    ---@diagnostic enable: missing-fields
    if defender then
        draw_animation(animation_name, defender, surface)
    end
end

---@param ability_data active_ability_data
---@param player LuaPlayer
---@param character LuaEntity
local function activate_landmine_ability(ability_data, player, character)
    local animation_name = "buff"
    local surface = character.surface
    local force = character.force
    local radius = math.random(0, ability_data.radius)
    local random_angle = math.random() * 2 * math.pi
    local position = get_position_on_circumference(character.position, radius, random_angle)
    local non_colliding_position = surface.find_non_colliding_position("land-mine", position, radius, 0.25)
    if not non_colliding_position then return end
    ---@diagnostic disable: missing-fields
    local landmine = surface.create_entity{
        name = "land-mine",
        position = non_colliding_position,
        force = force,
        target = character,
        source = character,
        character = character,
        player = player,
    }
    ---@diagnostic enable: missing-fields
    if landmine then
        draw_animation(animation_name, landmine, surface)
    end
end

---@param ability_data active_ability_data
---@param player LuaPlayer
---@param character LuaEntity
local function activate_poison_capsule_ability(ability_data, player, character)
    local surface = character.surface
    local force = character.force
    local radius = ability_data.radius
    local angle = direction_to_angle(opposite_direction(character.direction))
    local position = get_position_on_circumference(character.position, radius, angle)
    ---@diagnostic disable: missing-fields
    surface.create_entity{
        name = "poison-capsule",
        position = position,
        force = force,
        target = position,
        source = character,
        character = character,
        player = player,
        speed = 1/50,
    }
    ---@diagnostic enable: missing-fields
    local final_tick = game.tick + 60 * 45
    register_poison_zone(ability_data.name, position, player, final_tick)
end

---@param ability_data active_ability_data
---@param player LuaPlayer
---@param character LuaEntity
local function activate_slowdown_capsule_ability(ability_data, player, character)
    local surface = character.surface
    local force = character.force
    local radius = ability_data.radius
    for _, direction in pairs(defines.direction) do
        local angle = direction_to_angle(direction)
        local position = get_position_on_circumference(character.position, radius, angle)
        ---@diagnostic disable: missing-fields
        surface.create_entity{
            name = "slowdown-capsule",
            position = position,
            force = force,
            target = position,
            source = character,
            character = character,
            player = player,
            speed = 1/50,
        }
        ---@diagnostic enable: missing-fields
    end
    if radius > 10 and (radius % 10 == 0) then
        local secondary_ability_data = {
            radius = radius / 2,
        }
        activate_slowdown_capsule_ability(secondary_ability_data, player, character)
    end
end

---@param ability_data active_ability_data
---@param player LuaPlayer
---@param character LuaEntity
local function activate_gun_turret_ability(ability_data, player, character)
    local animation_name = "buff"
    local surface = character.surface
    local force = character.force
    local radius = ability_data.radius
    local angle = direction_to_angle(player.character.direction)
    refill_existing_turrets(ability_data, character)
    for i = 1, 2 do
        local degrees = i == 1 and -15 or 15
        local offset_angle = angle + degrees_to_radians(degrees)
        local position = get_position_on_circumference(character.position, radius, offset_angle)
        local non_colliding_position = surface.find_non_colliding_position("gun-turret", position, radius, 1)
        if non_colliding_position then
        ---@diagnostic disable: missing-fields
            local turret = surface.create_entity{
                name = "gun-turret",
                position = non_colliding_position,
                force = force,
                target = position,
                source = character,
                character = character,
                player = player,
            }
            ---@diagnostic enable: missing-fields
            if turret then
                refill_infividual_turret_ammo(turret, ability_data)
                draw_animation(animation_name, turret, surface, 0, 2)
            end
        end
    end
end

---@param ability_data active_ability_data
---@param player LuaPlayer
---@param character LuaEntity
local function activate_shotgun_ability(ability_data, player, character)
    local surface = player.surface
    local radius = ability_data.radius
    local angle = direction_to_angle(player.character.direction)
    for _ = 1, 2 do
        for i = -10, 10 do
            local offest_angle = angle + degrees_to_radians(i)
            local target_position = get_position_on_circumference(player.position, radius, offest_angle)
            local source_position = get_position_on_circumference(player.position, 2, angle)
                ---@diagnostic disable: missing-fields
            local bullet = surface.create_entity{
                name = "shotgun-pellet",
                position = source_position,
                force = player.force,
                target = target_position,
                source = player.character,
                character = player.character,
                player = player,
                speed = 1.5,
                max_range = ability_data.radius * 2,
            }
            ---@diagnostic enable: missing-fields
        end
    end
end

---@param ability_data active_ability_data
---@param player LuaPlayer
---@param character LuaEntity
local function activate_flamethrower_ability(ability_data, player, character)
    local animation_name = ability_data.name
    local ability_radius = ability_data.radius
    local position = character.position
    local surface = character.surface
    local orientation = character.orientation
    local final_tick = game.tick + math.ceil(raw_abilities_data[animation_name].frame_count * 2/3)
    local angle = direction_to_angle(player.character.direction)
    position = position or get_position_on_circumference(player.position, ability_radius, angle)
    local count =  math.floor(ability_radius / 5)
    for i = -count, count do
        local offset_angle = angle + degrees_to_radians(i * (40 / count))
        local offset_position = get_position_on_circumference(position, ability_radius, offset_angle)
        draw_animation(animation_name, offset_position, surface, orientation, scale)
        create_flamethrower_target(animation_name, offset_position, player, final_tick)
    end
end

---@param ability_data active_ability_data
---@param player LuaPlayer
---@param character LuaEntity
local function activate_acid_sponge_ability(ability_data, player, character)
    local animation_name = ability_data.name
    local surface = character.surface
    local radius = ability_data.radius
    local position = character.position
    local acids_to_sponge = surface.find_entities_filtered{
        position = position,
        radius = radius,
        force = "enemy",
        type = {"stream", "fire", "projectile"},
    }
    for _, acid in pairs(acids_to_sponge) do
        if acid.valid then
            draw_animation(animation_name, acid.position, surface)
            acid.destroy()
        end
    end
end

---@param ability_data active_ability_data
---@param player LuaPlayer
---@param character LuaEntity
local function activate_crystal_blossom_ability(ability_data, player, character)
    local animation_name = ability_data.name
    local surface = character.surface
    local ability_radius = ability_data.radius
    local animation_radius = 1
    local position = character.position
    local damage = ability_data.damage
    local damage_per_tick = damage / aoe_damage_modifier
    local max_count = math.ceil(ability_radius / 3)
    local frame_count = raw_abilities_data[animation_name].frame_count
    local final_tick = game.tick + frame_count
    for i = 1, max_count do
        local random_angle = math.random() * 2 * math.pi
        local random_radius = math.random(0, ability_radius)
        local random_position = get_position_on_circumference(position, random_radius, random_angle)
        draw_animation(animation_name, random_position, surface, 0, animation_radius, frame_count)
        register_damage_zone(animation_name, animation_radius, damage_per_tick, player, random_position, surface, final_tick)
    end
end

local ability_functions = {
    burst = activate_burst_ability,
    punch = activate_punch_ability,
    cure = activate_cure_ability,
    slash = activate_slash_ability,
    rocket_launcher = activate_rocket_launcher_ability,
    pavement = activate_pavement_ability,
    beam_blast = activate_beam_blast_ability,
    discharge_defender = activate_discharge_defender_ability,
    destroyer = activate_destroyer_capsule_ability,
    distractor = activate_distractor_capsule_ability,
    defender = activate_defender_capsule_ability,
    landmine = activate_landmine_ability,
    poison_capsule = activate_poison_capsule_ability,
    slowdown_capsule = activate_slowdown_capsule_ability,
    gun_turret = activate_gun_turret_ability,
    shotgun = activate_shotgun_ability,
    barrier = activate_flamethrower_ability,
    purifying_light = activate_acid_sponge_ability,
    crystal_blossom = activate_crystal_blossom_ability,
}

---@param ability_data active_ability_data
---@param player LuaPlayer
---@param character LuaEntity
local function activate_ability(ability_data, player, character)
    local ability_name = ability_data.name
    local activate = ability_functions and ability_functions[ability_name]
    if activate then
        activate(ability_data, player, character)
    end
end

---@param ability_name string
---@param ability_data active_ability_data
---@param player LuaPlayer
local function upgrade_damage(ability_name, ability_data, player)
    ability_data.damage = ability_data.damage * ability_data.damage_multiplier
    local text = {"", { "ability_name." .. ability_name }, " [", {"upgrade_locale.lvl"}, " ", ability_data.level, "] ", {"upgrade_locale.damage"}, " ", ability_data.damage}
    draw_upgrade_text(text, player)
    -- activate_ability(ability_name, ability_data, player)
end

---@param ability_name string
---@param ability_data active_ability_data
---@param player LuaPlayer
local function upgrade_radius(ability_name, ability_data, player)
    ability_data.radius = ability_data.radius + ability_data.radius_multiplier
    local text = {"", { "ability_name." .. ability_name }, " [", {"upgrade_locale.lvl"}, " ", ability_data.level, "] ", {"upgrade_locale.radius"}, " ", ability_data.radius}
    draw_upgrade_text(text, player)
    -- activate_ability(ability_name, ability_data, player)
end

---@param ability_name string
---@param ability_data active_ability_data
---@param player LuaPlayer
local function upgrade_cooldown(ability_name, ability_data, player)
    ability_data.cooldown = math.max(1, math.ceil(ability_data.cooldown - ability_data.cooldown_multiplier))
    local text = {"", { "ability_name." .. ability_name }, " [", {"upgrade_locale.lvl"}, " ", ability_data.level, "] ", {"upgrade_locale.cooldown"}, " ", ability_data.cooldown}
    draw_upgrade_text(text, player)
    -- activate_ability(ability_name, ability_data, player)
end

local ability_upgrade_functions = {
    damage = upgrade_damage,
    radius = upgrade_radius,
    cooldown = upgrade_cooldown,
}

---@param ability_data active_ability_data
---@param player LuaPlayer
local function upgrade_named_ability(ability_data, player)
    local upgrade_type = ability_data.upgrade_order[ability_data.level]
    local upgrade = ability_upgrade_functions[upgrade_type]
    if upgrade then
        ability_data.level = ability_data.level + 1
        upgrade(ability_data.name, ability_data, player)
        update_arena_gui_ability_info(player, ability_data)
    end
end

---@param player LuaPlayer
local function upgrade_random_ability(player)
    local player_data = global.player_data[player.index]
    local abilities = player_data.abilities
    local upgradeable_abilities = {} --[[@type string[]\]]
    for _, ability in pairs(abilities) do
        local level = ability.level
        if ability.upgrade_order[level] then
            table.insert(upgradeable_abilities, ability.name)
        end
    end
    if #upgradeable_abilities == 0 then
        draw_announcement_text({ "upgrade_locale.all_abilities_max_level" }, player)
        return
    end
    local ability_name = upgradeable_abilities[math.random(#upgradeable_abilities)]
    local ability_data = abilities[ability_name]
    upgrade_named_ability(ability_data, player)
end

---@param ability_name string
---@param player LuaPlayer
local function unlock_named_ability(ability_name, player)
    local player_data = global.player_data[player.index]
    if not player_data.abilities[ability_name] then
        local raw_data = raw_abilities_data[ability_name]
        player_data.abilities[ability_name] = {
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
        local text = {"", { "ability_name." .. ability_name }, " [lvl 1] unlocked!"}
        draw_upgrade_text(text, player, { x = 0, y = 3 })
        add_arena_gui_ability_info(player, player_data.abilities[ability_name])
        global.healing_players = global.healing_players or {}
        global.healing_players[player.index] = {
            player = player,
            damage = - player.character.prototype.max_health / (60 * 15),
            final_tick = game.tick + (60 * 15),
        }
    end
end

---@param player LuaPlayer
local function unlock_random_ability(player)
    local ability_names = {} --[[@type string[]\]]
    local player_abilities = global.player_data[player.index].abilities
    for name, available in pairs(global.available_abilities) do
        if available and not player_abilities[name] then
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

---@param surface LuaSurface
---@param position MapPosition
---@param name string
---@param player LuaPlayer?
local function spawn_new_enemy(surface, position, name, player)
    ---@diagnostic disable: missing-fields
    local enemy = surface.create_entity{
        name = name,
        position = position,
        force = game.forces.enemy,
        target = player and player.character or nil,
    }
    ---@diagnostic enable: missing-fields
end

---@param player LuaPlayer
local function spawn_level_appropriate_enemy(player)
    if player.controller_type ~= defines.controllers.character then return end

    local arena_ticks = arena_ticks_elapsed()
    local arena_minutes = arena_ticks / 60 / 60
    local enemy_name = "small-biter"
    local chance = 15 / 100

    local enemy_types = {
        {name = "small-spitter", minute = 2, chance = chance - 1/100},
        {name = "medium-biter", minute = 3, chance = chance - 2/100},
        {name = "medium-spitter", minute = 4, chance = chance - 3/100},
        {name = "small-worm-turret", minute = 5, chance = chance - 4/100},
        {name = "big-biter", minute = 6, chance = chance - 5/100},
        {name = "big-spitter", minute = 7, chance = chance - 6/100},
        {name = "medium-worm-turret", minute = 8, chance = chance - 7/100},
        {name = "behemoth-biter", minute = 9, chance = chance - 8/100},
        {name = "behemoth-spitter", minute = 10, chance = chance - 9/100},
        {name = "big-worm-turret", minute = 12, chance = chance - 10/100},
        {name = "behemoth-worm-turret", minute = 14, chance = chance - 11/100},
        {name = "behemoth-worm-turret", minute = 15, chance = 1},
    }

    for _, enemy_type in ipairs(enemy_types) do
        if arena_minutes >= enemy_type.minute and math.random() < enemy_type.chance then
            enemy_name = enemy_type.name
        end
    end

    local radius = math.random(25, 50)
    if arena_ticks > global.game_duration[global.lobby_options.difficulty] then
        radius = math.random(15, 150)
    end

    local position = get_random_position_on_circumference(player.position, radius)
    local surface = player.surface
    position = surface.find_non_colliding_position(enemy_name, position, 100, 1) or position
    spawn_new_enemy(surface, position, enemy_name, player)
end

---@param event EventData.on_player_died
local function on_player_died(event)
    game.set_game_state {
        game_finished = false,
    }
    local player = game.get_player(event.player_index)
    if not player then return end
    local ticks_remaining = arena_ticks_remaining()
    local player_is_in_lobby = player.surface.name == "lobby"
    local less_than_nine_seconds_remaining = (ticks_remaining <= 60 * 9) and (ticks_remaining > 0)
    local lobby_ticks = player_is_in_lobby and (60 * 5)
    local close_finish_ticks = less_than_nine_seconds_remaining and math.ceil(ticks_remaining / 3)
    local arena_ticks = 60 * 8
    local ticks = lobby_ticks or close_finish_ticks or arena_ticks
    player.ticks_to_respawn = ticks

    if global.game_state == "arena" then
        local player_stats = global.statistics[player.index]
        if player_stats then
            player_stats.total.deaths = player_stats.total.deaths + 1
            player_stats.last_attempt.deaths = player_stats.last_attempt.deaths + 1
        end
        global.remaining_lives = global.remaining_lives or {}
        global.remaining_lives[player.index] = global.remaining_lives[player.index] or 0
        local text = { "", { "message_locale.engineer_down" }, "! ", global.remaining_lives[player.index], " ", { "message_locale.lives_remaining" } }
        if ticks_remaining <= 0 then
            text = { "", { "message_locale.engineer_victorious" }, "!" }
        end
        draw_upgrade_text(text, player, { x = 0, y = 3 })
    end
end

---@param event EventData.on_entity_died|EventData.on_entity_damaged
---@return LuaPlayer?
local function get_damage_attribution(event)
    local player = nil
    local cause = event.cause
    if cause then
        local cause_type = cause.type
        if cause_type == "character" then
            if cause.player then
                player = cause.player
            end
        elseif cause_type == "combat-robot" then
            if cause.combat_robot_owner then
                player = cause.combat_robot_owner.player
            end
        elseif cause_type == "land-mine" then
            if cause.last_user then
                player = cause.last_user --[[@as LuaPlayer]]
            end
        elseif cause_type == "ammo-turret" then
            if cause.last_user then
                player = cause.last_user --[[@as LuaPlayer]]
            end
        end
    end
    local damage_type = event.damage_type
    if damage_type then
        local damage_type_name = damage_type.name
        if damage_type_name == "fire" then
            local position = event.entity.position
            for id, zone in pairs(global.burn_zones) do
                local distance_from_target = distance(position, zone.position)
                if distance_from_target <= 4 then
                    player = zone.player.valid and zone.player or nil
                    break
                end
                if zone.final_tick < game.tick then
                    global.burn_zones[id] = nil
                end
            end
        elseif damage_type_name == "poison" then
            local position = event.entity.position
            for id, zone in pairs(global.poison_zones) do
                local distance_from_target = distance(position, zone.position)
                if distance_from_target <= 15 then
                    player = zone.player.valid and zone.player or nil
                    break
                end
                if zone.final_tick < game.tick then
                    global.poison_zones[id] = nil
                end
            end
        end
    end
    return player
end

---@param event EventData.on_entity_damaged
local function on_entity_damaged(event)
    local entity = event.entity
    local surface = entity.surface
    local damage = math.ceil(event.final_damage_amount)
    local flying_text = ((damage > 0) and ("-" .. damage)) or ("+" .. damage)
    local color = ((damage > 0 )and {r = 1, g = 0, b = 0}) or {r = 0, g = 1, b = 0}
    ---@diagnostic disable: missing-fields
    surface.create_entity{
        name = "flying-text",
        position = entity.position,
        text = flying_text,
        color = color,
    }
    ---@diagnostic enable: missing-fields
    if surface.name == "lobby" then
        if entity.type == "character" then
            -- entity.health = entity.health + event.final_damage_amount
            entity.damage( - event.final_damage_amount, entity.force, "impact")
        else
            entity.die()
        end
    end
    if surface.name == "arena" then
        if entity.force == game.forces.player then
            local player = get_damage_attribution(event)
            if player then
                entity.health = entity.health + event.final_damage_amount * 0.75
            end
        end
    end
end

---@param level_threshold uint
local function upgrade_damage_bonuses(level_threshold)
    local all_players_meet_requirement = true
    for _, player in pairs(game.connected_players) do
        local player_data = global.player_data[player.index]
        if player_data.level < level_threshold then
            all_players_meet_requirement = false
            break
        end
    end
    if all_players_meet_requirement then
        local technology_upgrades_by_modifier = {
            [3] = {
                ["follower-robot-count-"] = true,
            },
            [5] = {
                ["physical-projectile-damage-"] = true,
                ["energy-weapons-damage-"] = true,
                ["stronger-explosives-"] = true,
                ["refined-flammables-"] = true,
            },
            [7] = {
                ["weapon-shooting-speed-"] = true,
            },
        }
        local arena_minutes = arena_ticks_elapsed() / 60 / 60
        for modifier, technologies in pairs(technology_upgrades_by_modifier) do
            local force = game.forces.player
            for i = 1, math.ceil(arena_minutes / modifier) do
                for name, _ in pairs(technologies) do
                    local tech_name = name .. math.min(i, 7)
                    local technology = force.technologies[tech_name]
                    if not technology then break end
                    local prerequisites = technology.prerequisites
                    for _, prerequisite in pairs(prerequisites) do
                        force.technologies[prerequisite.name].researched = true
                    end
                    force.technologies[tech_name].researched = true
                end
            end
        end
    end
end

---@param event EventData.on_entity_died
local function on_entity_died(event)
    local entity = event.entity
    local surface = entity.surface
    if not (surface.name == "arena") then return end
    if entity.type == "character" then
        ---@diagnostic disable: missing-fields
        surface.create_entity{
            name = "atomic-rocket",
            position = entity.position,
            force = entity.force,
            speed = 10,
            target = entity.position,
        }
        ---@diagnostic enable: missing-fields
    end
    local player = get_damage_attribution(event)
    local character = valid_player_character(player)
    if player and character then
        if not (player.surface.name == "arena") then return end
        local player_index = player.index
        local player_stats = global.statistics[player_index] --[[@type player_statistics]]
        if player_stats then
            player_stats.total.kills = player_stats.total.kills + 1
            player_stats.last_attempt.kills = player_stats.last_attempt.kills + 1
        end
        local player_data = global.player_data[player_index]
        player_data.exp = player_data.exp + 1
        if player_data.exp >= 3 * player_data.level then
            player_data.exp = 0
            player_data.level = player_data.level + 1
            local level = player_data.level
            upgrade_random_ability(player)
            draw_animation("shimmer", character, surface, 0, 2)
            if level % 8 == 0 then
                unlock_random_ability(player)
            end
            global.remaining_lives = global.remaining_lives or {}
            global.remaining_lives[player_index] = global.remaining_lives[player_index] or 0
            if level % 33 == 0 then
                global.remaining_lives[player_index] = global.remaining_lives[player_index] + 1
                draw_upgrade_text({"", {"message_locale.level_up"}, "! ", global.remaining_lives[player_index], " ", {"message_locale.lives_remaining"}}, player, { x = 0, y = 3 })
            end
            if level % 2 == 0 then
                upgrade_damage_bonuses(level)
            end
        end
        local difficulty_spawn_chances = {
            ["easy"] = 0.75,
            ["normal"] = 0.9,
            ["hard"] = 1,
        }
        local difficulty = global.lobby_options.difficulty
        local chance = difficulty_spawn_chances[difficulty]
        if math.random() <= chance then
            spawn_level_appropriate_enemy(player)
        end
    end
end

---@param event EventData.on_player_respawned
local function on_player_respawned(event)
    if not (global.game_state == "arena") then return end
    local player_index = event.player_index
    local player = game.get_player(player_index)
    if not player then return end
    player.character_running_speed_modifier = 0.4
    global.remaining_lives = global.remaining_lives or {}
    global.remaining_lives[player_index] = global.remaining_lives[player_index] or 0
    if global.remaining_lives[player_index] < 1 then
        local character = player.character
        player.set_controller{type = defines.controllers.spectator}
        if character then
            character.destroy()
        end
    end
    global.remaining_lives[player_index] = global.remaining_lives[player_index] - 1
end

---@param player LuaPlayer
local function reset_health(player)
    local character = player.character
    if not character then return end
    character.health = character.prototype.max_health
end

---@param player LuaPlayer
local function initialize_player_data(player)
    local starting_ability = global.lobby_options.starting_ability
    local ability_name = global.default_abilities[starting_ability]
    set_ability(ability_name, player)
    initialize_player_statistics(player.index)
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
    if not game.surfaces.arena then
        game.create_surface("arena", map_gen_settings)
        game.surfaces.arena.always_day = true
    end
end

local function replenish_arena_enemies()
    local arena_surface = game.surfaces.arena
    local enemies = {
        "small-worm-turret",
        "medium-worm-turret",
        "big-worm-turret",
        "behemoth-worm-turret",
        "biter-spawner",
        "spitter-spawner",
    }
    arena_surface.regenerate_entity(enemies)
end

local function destroy_arena_enemies()
    local enemies = game.surfaces.arena.find_entities_filtered{
        force = "enemy",
    }
    for _, enemy in pairs(enemies) do
        enemy.destroy()
    end
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
            destroy_arena_enemies()
            replenish_arena_enemies()
            global.game_state = "arena"
            global.arena_start_tick = game.tick
            for _, player in pairs(players) do
                local following_robots = player.following_robots
                for _, robot in pairs(following_robots) do
                    robot.destroy()
                end
                local position = game.get_surface("arena").find_non_colliding_position("character", {x = 0, y = 0}, 100, 1)
                position = position or {x = player.index * 2, y = 0}
                player.teleport(position, "arena")
                player.character_running_speed_modifier = 0.4
                new_attempt_stats_reset(player.index)
                create_arena_gui(player)
                local abilities = global.player_data[player.index].abilities
                for _, ability_data in pairs(abilities) do
                    activate_ability(ability_data, player, player.character)
                end
            end
        end
    end
end

---@param event EventData.on_entity_color_changed
local function on_entity_color_changed(event)
    local entity = event.entity
    if entity.type == "character" then
        if entity.player then
            update_statistics()
        end
    end
end

local function update_statistics_colors()
    global.player_chat_colors = global.player_chat_colors or {}
    for _, player in pairs(game.players) do
        local index = player.index
        local new = player.chat_color
        local old = global.player_chat_colors[index]
        if old then
            if not ((new.r == old.r) and (new.g == old.g) and (new.b == old.b)) then
                update_statistics()
            end
        end
        global.player_chat_colors[index] = new
    end
end

local function respawn_lobby_practice_enemy()
    local lobby_surface = game.surfaces.lobby
    local enemies = lobby_surface.find_entities_filtered { type = "unit", force = "enemy", position = { x = 0, y = 0 }, radius = 100 }
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

---@param event EventData.on_player_joined_game
local function on_player_joined_game(event)
    local game_state = global.game_state
    local player_index = event.player_index
    local player = game.get_player(player_index)
    if not player then return end
    -- local player_data = global.player_data[player_index]
    -- if not player_data then
    --     initialize_player_data(player)
    -- end
    if game_state == "lobby" then
        player.teleport({x = -20, y = 0}, "lobby")
    elseif game_state == "arena" then
        local character = valid_player_character(player)
        player.set_controller{type = defines.controllers.spectator}
        if character then character.destroy() end
        player.teleport({x = 0, y = 0}, "arena")
    end
end

---@param event EventData.on_tick
local function on_tick(event)

    if not script.level and script.level.mod_name == "asher_sky" then return end
    global.game_state = global.game_state or "lobby"
    local connected_players = game.connected_players
    local game_tick = game.tick
    local game_state = global.game_state

    -- lobby mode --
    if game_state == "lobby" then

        local lobby_surface = game.surfaces.lobby
        initialize_lobby()
        for _, player in pairs(connected_players) do
            local position = player.position
            if not (player.surface_index == lobby_surface.index) then
                player.teleport(position, lobby_surface)
            end
            if not player.character then return end
            if player.character_running_speed_modifier < 0.4 then
                player.character_running_speed_modifier = 0.4
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
                    if not (lobby_options.starting_ability == "ability_1") then
                        set_starting_ability("ability_1", player)
                    end
                elseif x < 3 and x > -3 then
                    if not (lobby_options.starting_ability == "ability_2") then
                        set_starting_ability("ability_2", player)
                    end
                elseif x < 10 and x > 4 then
                    if not (lobby_options.starting_ability == "ability_3") then
                        set_starting_ability("ability_3", player)
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
        initialize_statistics()
        if game_tick % (60 * 25) == 0 then
            respawn_lobby_practice_enemy()
        end
        if game_tick % (60 * 2) == 0 then
            update_statistics_colors()
        end
    end

    -- lobby and arena --

    for _, player in pairs(connected_players) do
        global.player_data[player.index] = global.player_data[player.index] or initialize_player_data(player)
        local player_data = global.player_data[player.index]
        for ability_name, ability_data in pairs(player_data.abilities) do
            if (((event.tick + (player.index * 25)) % ability_data.cooldown) == 0) then
                local character = valid_player_character(player)
                if character then
                    activate_ability(ability_data, player, character)
                end
            end
        end
    end
    for id, damage_zone in pairs(global.damage_zones) do
        local player = damage_zone.player
        if player.valid then
            damage_enemies_in_radius(damage_zone.radius, damage_zone.damage_per_tick, damage_zone.position, damage_zone.surface, player)
        end
        if damage_zone.final_tick <= event.tick then
            global.damage_zones[id] = nil
        end
    end
    for id, healing_player in pairs(global.healing_players) do
        local player = healing_player.player
        if player.valid then
            local character = player.character
            if character then
                character.damage(healing_player.damage, "enemy", "impact")
            end
        end
        if healing_player.final_tick <= event.tick then
            global.healing_players[id] = nil
        end
    end
    for id, flamethrower_target in pairs(global.flamethrower_targets) do
        local player = flamethrower_target.player
        if player.valid then
            if player.character then
                activate_flamethrower(player, flamethrower_target.position)
            end
        end
        if flamethrower_target.final_tick <= event.tick then
            global.flamethrower_targets[id] = nil
        end
    end
    for id, laser_beam_target in pairs(global.laser_beam_targets) do
        local player = laser_beam_target.player
        local character = valid_player_character(player)
        if character then
            local target = laser_beam_target.target --[[@as LuaEntity]]
            if target.valid then
                local ability_data = laser_beam_target.ability_data --[[@type active_ability_data]]
                local damage = ability_data.damage / aoe_damage_modifier --[[@as float]]
                target.damage(damage, player.force, "laser", character)
            end
        end
        local primary_target = laser_beam_target.primary_target --[[@as LuaEntity]]
        if not primary_target.valid then
            global.laser_beam_targets[id] = nil
        elseif laser_beam_target.final_tick <= event.tick then
            global.laser_beam_targets[id] = nil
        end
    end

    -- arena mode --

    if game_state == "arena" then
        local difficulties = {
            easy = 40,
            normal = 25,
            hard = 10,
        }
        for _, player in pairs(connected_players) do
            local character = valid_player_character(player)
            if character then
                local player_index = player.index
                local arena_gui = player.gui.screen.arena_gui
                local player_stats = global.statistics[player_index]
                if game_tick % 30 == 0 then
                    local kpm = calculate_kills_per_minute(player_index)
                    update_kpm_statistics(player_index, kpm)
                    update_arena_gui_kills_per_minute(player, arena_gui, player_stats)
                    update_arena_gui_time_remaining(player, arena_gui, player_stats)
                    update_arena_gui_lives_remaining(player, arena_gui, player_stats)
                end
                if game_tick % 5 == 0 then
                    update_arena_gui_kills(player, arena_gui, player_stats)
                end
                local balance = difficulties[global.lobby_options.difficulty]
                if game_tick % balance == 0 then
                    spawn_level_appropriate_enemy(player)
                end

                local position = player.position
                global.previous_positions = global.previous_positions or {}
                global.previous_positions[player_index] = global.previous_positions[player_index] or position
                local previous_position = global.previous_positions[player_index]
                if position.x == previous_position.x and position.y == previous_position.y then
                    local chance = 75/100
                    if arena_ticks_elapsed() <= 60 * 60 * 0.75 then
                        chance = 15/100
                    end
                    if math.random() < chance then
                        spawn_level_appropriate_enemy(player)
                    end
                end
                global.previous_positions[player_index] = position
            end
        end

        local difficulty = global.lobby_options.difficulty
        local max_game_duration = global.game_duration[difficulty]
        local current_arena_duration = arena_ticks_elapsed()
        if current_arena_duration == max_game_duration then
            local someone_is_alive = false
            for _, player in pairs(connected_players) do
                local character = valid_player_character(player)
                if character then
                    local text = {"", {"message_locale.victory_lap"}, "!"}
                    draw_announcement_text(text, player)
                    someone_is_alive = true
                end
            end
            if someone_is_alive then
                for _, player in pairs(connected_players) do
                    local player_stats = global.statistics[player.index] --[[@type player_statistics]]
                    player_stats.total.victories = player_stats.total.victories + 1
                    player_stats.last_attempt.victories = player_stats.last_attempt.victories + 1
                    global.remaining_lives[player.index] = 0
                end
            end
        end
        if current_arena_duration > max_game_duration then
            for _, player in pairs(connected_players) do
                spawn_level_appropriate_enemy(player)
            end
        end
        local all_players_dead = true
        for _, player in pairs(connected_players) do
            if not (player.controller_type == defines.controllers.spectator) then
                all_players_dead = false
            end
            if not (player.controller_type == defines.controllers.character) then
                local nearest_enemy = find_nearest_enemy(player.position, 125, player.force, player.surface)
                if nearest_enemy then
                    ---@diagnostic disable: missing-fields
                    player.surface.create_entity{
                        name = "explosive-rocket",
                        position = player.position,
                        force = player.force,
                        target = nearest_enemy,
                        speed = 1 / 60,
                    }
                    ---@diagnostic enable: missing-fields
                end
            end
        end
        if all_players_dead then
            for _, player in pairs(connected_players) do
                player.teleport({x = -20, y = 0}, "lobby")
                player.set_controller{type = defines.controllers.god}
                local character = player.create_character() and player.character
                initialize_player_data(player)
                destroy_arena_gui(player)
            end
            global.game_state = "lobby"
            global.arena_start_tick = nil
            global.kill_counter_render_ids = nil
            global.remaining_lives = nil
            global.kpm_counter_render_ids = nil
            game.forces.player.reset()
            randomize_starting_abilities()
            update_lobby_text()
            update_statistics()
            destroy_arena_enemies()
        end
    end
end

-- [[ event registration ]] -- 

script.on_init(on_init)
script.on_event(defines.events.on_tick, on_tick)
script.on_event(defines.events.on_entity_died, on_entity_died)
script.on_event(defines.events.on_player_respawned, on_player_respawned)
script.on_event(defines.events.on_player_died, on_player_died)
script.on_event(defines.events.on_entity_damaged, on_entity_damaged)
script.on_event(defines.events.on_entity_color_changed, on_entity_color_changed)
script.on_event(defines.events.on_player_joined_game, on_player_joined_game)


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
    }
    global.available_starting_abilities = {
        burst = true,
        punch = true,
        -- cure = true,
        slash = true,
        rocket_launcher = true,
        -- pavement = true,
        beam_blast = true,
        -- discharge_defender = true,
        destroyer = true,
        distractor = true,
        defender = true,
        -- landmine = true,
        -- poison_capsule = true,
        -- slowdown_capsule = true,
        -- gun_turret = true,
        shotgun = true,
        barrier = true,
    }
    global.default_abilities = {
        ability_1 = "destroyer",
        ability_2 = "poison_capsule",
        ability_3 = "defender",
    }
    global.statistics = {}
    global.flamethrower_targets = {}
    global.burn_zones = {}
    global.poison_zones = {}
    global.game_length = 60 * 60 * 15
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
    local target = raw_ability_data.target == "character" and character or position or player.position
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

---@param animation_name string
---@param ability_data active_ability_data
---@param player LuaPlayer
---@param position MapPosition?
local function draw_pavement(animation_name, ability_data, player, position)
    position = position or player.position
    local surface = player.surface
    local tile = surface.get_tile(position.x, position.y)
    local tile_name = tile.name
    local tile_tier = tile_tiers_by_name[tile_name] or 0
    local normalized_tile_tier = math.min(math.max(ability_data.level - 5, 0), tile_tier)
    local next_tile_name = tile_tiers_by_order[normalized_tile_tier + 1]
    if not next_tile_name then return end
    local tiles = {
        { name = next_tile_name, position = { x = position.x, y = position.y } }
    }
    if ability_data.radius > 1 then
        local radius = ability_data.radius - 1
        for x = -radius, radius do
            for y = -radius, radius do
                if x ~= 0 or y ~= 0 then
                    table.insert(tiles, { name = next_tile_name, position = { x = position.x + x, y = position.y + y } })
                end
            end
        end
    end
    surface.set_tiles(tiles)
end

---@param turret LuaEntity
---@param ability_data active_ability_data
local function refill_infividual_turret_ammo(turret, ability_data)
    local inventory = turret.get_inventory(defines.inventory.turret_ammo)
    local ammo_name =(( ability_data.level > 12 ) and "uranium-rounds-magazine") or (( ability_data.level > 6 ) and "piercing-rounds-magazine") or "firearm-magazine"
    local ammo_items = { name = ammo_name, count = math.max(5, ability_data.level)}
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

---@param degrees number
---@return number
local function degrees_to_radians(degrees)
    return degrees * (math.pi / 180)
end

---@param animation_name string
---@param ability_data active_ability_data
---@param player LuaPlayer
---@param position MapPosition?
local function draw_barrier(animation_name, ability_data, player, position)
    local angle = direction_to_angle(opposite_direction(player.character.direction))
    position = position or get_position_on_circumference(player.position, ability_data.radius, angle)
    local modified_ability_data = {
        radius = 2.5,
    }
    local count =  math.floor(ability_data.radius / 5)
    for i = -count, count do
        local offset_angle = angle + degrees_to_radians(i * (73 / count))
        local offset_position = get_position_on_circumference(position, ability_data.radius, offset_angle)
        draw_animation(animation_name, modified_ability_data, player, offset_position)
        local final_tick = game.tick + math.ceil(raw_abilities_data.barrier.frame_count * 2/3)
        create_flamethrower_target(animation_name, offset_position, player, final_tick)
    end
end

---@param player LuaPlayer
---@param target MapPosition|LuaEntity
local function draw_highlight_line(player, target)
    local target_offset = {0, 0}
    if target.type and target.type == "combat-robot" then
        target_offset = {0, -1}
    end
    rendering.draw_line{
        color = player.chat_color,
        width = 5,
        gap_length = 0,
        dash_length = 0,
        from = player.character,
        to = target,
        to_offset = target_offset,
        surface = player.surface,
        time_to_live = 60 * 2,
        draw_on_ground = true,
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

---@param animation_name string
---@param ability_data active_ability_data
---@param player LuaPlayer
---@param position MapPosition?
local function refill_and_repair_turrets(animation_name, ability_data, player, position)
    local nearby_turrets = player.surface.find_entities_filtered{
        position = position or player.position,
        radius = ability_data.radius,
        force = player.force,
        type = "ammo-turret",
    }
    if not nearby_turrets then return end
    nearby_turrets = filter_valid_entities(nearby_turrets)
    for _, turret in pairs(nearby_turrets) do
        refill_infividual_turret_ammo(turret, ability_data)
        turret.damage( -turret.prototype.max_health, player.force, "impact", player.character)
        draw_highlight_line(player, turret)
    end
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
        type = {"unit", "turret", "unit-spawner"},
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

local aoe_damage_modifier = 20

---@param ability_data active_ability_data
---@param player LuaPlayer
local function activate_burst_damage(ability_data, player)
    local position = player.position
    local surface = player.surface
    local radius = ability_data.radius
    local damage_per_tick = ability_data.damage / aoe_damage_modifier
    local final_tick = game.tick + (raw_abilities_data.burst.frame_count * 1.25)
    register_damage_zone("burst", radius, damage_per_tick, player, position, surface, final_tick)
end

---@param ability_data active_ability_data
---@param player LuaPlayer
local function activate_punch_damage(ability_data, player)
    local radius = ability_data.radius
    local damage = ability_data.damage --[[@as float]]
    local position = player.position
    local surface = player.surface
    damage_enemies_in_radius(radius, damage, position, surface, player)
    local damage_per_tick = damage / aoe_damage_modifier
    local final_tick = game.tick + (raw_abilities_data.punch.frame_count * 0.75)
    register_damage_zone("punch", radius, damage_per_tick, player, position, surface, final_tick)
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
    local position = player.position
    local force = player.force
    local radius = ability_data.radius
    local character = player.character
    local enemy = find_nearest_enemy(position, radius, force, surface)
    if not enemy then return end
    ---@diagnostic disable: missing-fields
    local rocket = surface.create_entity{
        name = "rocket",
        position = position,
        force = force,
        target = enemy,
        source = character,
        speed = 1/10,
        max_range = radius * 20,
        player = player,
    }
    ---@diagnostic enable: missing-fields
end

---@param surface LuaSurface
---@param position MapPosition
---@param target MapPosition|LuaEntity
---@param player LuaPlayer
local function create_laser_beam(surface, position, target, player)
    local beam_name = "laser-beam"
    ---@diagnostic disable: missing-fields
    local beam = surface.create_entity{
        name = beam_name,
        position = position,
        force = player.force,
        target = target,
        source = player.character,
        speed = 1/10,
        max_range = 100,
        duration = 33,
    }
    ---@diagnostic enable: missing-fields
end

---@param ability_data active_ability_data
---@param player LuaPlayer
local function activate_beam_blast(ability_data, player)
    local surface = player.surface
    local player_position = player.position
    local radius = ability_data.radius
    local enemy_1 = find_nearest_enemy(player_position, radius * 3, player.force, surface)
    if not enemy_1 then return end
    local enemy_1_id = enemy_1.unit_number
    local enemy_1_position = enemy_1.position
    local damage = ability_data.damage
    local damage_bonus = game.forces.player.get_turret_attack_modifier("laser-turret")
    damage = damage + (damage * damage_bonus) --[[@as float]]
    create_laser_beam(surface, player_position, enemy_1, player)
    local nearby_enemies_1 = get_enemies_in_radius(surface, enemy_1.position, radius / 2)
    for _, enemy_2 in pairs(nearby_enemies_1) do
        if enemy_2.unit_number ~= enemy_1_id then
            create_laser_beam(surface, enemy_1_position, enemy_2, player)
            if enemy_2.valid then
                enemy_2.damage(damage, player.force, "laser", player.character)
            end
        end
    end
    if enemy_1.valid then
        enemy_1.damage(damage, player.force, "laser", player.character)
    end
end

---@param ability_data active_ability_data
---@param player LuaPlayer
local function activate_discharge_defender(ability_data, player)
    local surface = player.surface
    ---@diagnostic disable: missing-fields
    local discharge_defender = surface.create_entity{
        name = "discharge-defender",
        position = player.position,
        direction = player.character.direction,
        force = player.force,
        -- target = enemy,
        target = player.character,
        source = player.character,
        speed = 1/10,
        max_range = ability_data.radius * 20,
        player = player,
    }
    ---@diagnostic enable: missing-fields
end

---@param ability_data active_ability_data
---@param player LuaPlayer
local function activate_destroyer_capsule(ability_data, player)
    local surface = player.surface
    ---@diagnostic disable: missing-fields
    local destroyer = surface.create_entity{
        name = "destroyer",
        position = player.position,
        direction = player.character.direction,
        force = player.force,
        -- target = enemy,
        target = player.character,
        source = player.character,
        speed = 1/10,
        max_range = ability_data.radius * 20,
        player = player,
    }
    ---@diagnostic enable: missing-fields
end

---@param ability_data active_ability_data
---@param player LuaPlayer
local function activate_distractor_capsule(ability_data, player)
    local surface = player.surface
    ---@diagnostic disable: missing-fields
    local distractor = surface.create_entity{
        name = "distractor",
        position = player.position,
        direction = player.character.direction,
        force = player.force,
        -- target = enemy,
        target = player.character,
        source = player.character,
        speed = 1/10,
        max_range = ability_data.radius * 20,
        player = player,
    }
    ---@diagnostic enable: missing-fields
    if distractor then
        draw_highlight_line(player, distractor)
    end
end

---@param ability_data active_ability_data
---@param player LuaPlayer
local function activate_defender_capsule(ability_data, player)
    local surface = player.surface
    ---@diagnostic disable: missing-fields
    local defender = surface.create_entity{
        name = "defender",
        position = player.position,
        direction = player.character.direction,
        force = player.force,
        -- target = enemy,
        target = player.character,
        source = player.character,
        speed = 1/10,
        max_range = ability_data.radius * 20,
        player = player,
    }
    ---@diagnostic enable: missing-fields
end

---@param ability_data active_ability_data
---@param player LuaPlayer
local function activate_landmine_deployer(ability_data, player)
    local surface = player.surface
    local radius = math.random(0, ability_data.radius)
    local random_angle = math.random() * 2 * math.pi
    local position = get_position_on_circumference(player.position, radius, random_angle)
    local non_colliding_position = surface.find_non_colliding_position("land-mine", position, radius, 0.25)
    if not non_colliding_position then return end
    ---@diagnostic disable: missing-fields
    local landmine = surface.create_entity{
        name = "land-mine",
        position = non_colliding_position,
        force = player.force,
        target = player.character,
        source = player.character,
        character = player.character,
        player = player,
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

---@param ability_data active_ability_data
---@param player LuaPlayer
local function activate_poison_capsule_deployer(ability_data, player)
    local surface = player.surface
    local radius = ability_data.radius
    local angle = direction_to_angle(opposite_direction(player.character.direction))
    local position = get_position_on_circumference(player.position, radius, angle)
    ---@diagnostic disable: missing-fields
    surface.create_entity{
        name = "poison-capsule",
        position = position,
        force = player.force,
        target = position,
        source = player.character,
        character = player.character,
        player = player,
        speed = 1/500,
    }
    ---@diagnostic enable: missing-fields
    local final_tick = game.tick + 60 * 45
    register_poison_zone(ability_data.name, position, player, final_tick)
end

---@param ability_data active_ability_data
---@param player LuaPlayer
local function activate_slowdown_capsule_deployer(ability_data, player)
    local surface = player.surface
    local radius = ability_data.radius
    for _, direction in pairs(defines.direction) do
        local angle = direction_to_angle(direction)
        local position = get_position_on_circumference(player.position, radius, angle)
        ---@diagnostic disable: missing-fields
        surface.create_entity{
            name = "slowdown-capsule",
            position = position,
            force = player.force,
            target = position,
            source = player.character,
            character = player.character,
            player = player,
            speed = 1/500,
        }
        ---@diagnostic enable: missing-fields
    end
    if radius > 10 and (radius % 10 == 0) then
        local secondary_ability_data = {
            radius = radius / 2,
        }
        activate_slowdown_capsule_deployer(secondary_ability_data, player)
    end
end

---@param ability_data active_ability_data
---@param player LuaPlayer
local function activate_gun_turret_deployer(ability_data, player)
    local surface = player.surface
    local radius = ability_data.radius
    local angle = direction_to_angle(player.character.direction)
    for i = 1, 2 do
        local degrees = i == 1 and -15 or 15
        local offset_angle = angle + degrees_to_radians(degrees)
        local position = get_position_on_circumference(player.position, radius, offset_angle)
        local non_colliding_position = surface.find_non_colliding_position("gun-turret", position, radius, 0.25)
        if non_colliding_position then
        ---@diagnostic disable: missing-fields
            local turret = surface.create_entity{
                name = "gun-turret",
                position = non_colliding_position,
                force = player.force,
                target = position,
                source = player.character,
                character = player.character,
                player = player,
                speed = 1/500,
            }
            ---@diagnostic enable: missing-fields
            if turret then
                refill_infividual_turret_ammo(turret, ability_data)
                draw_highlight_line(player, turret)
            end
        end
    end
end

---@param ability_data active_ability_data
---@param player LuaPlayer
local function activate_shotgun(ability_data, player)
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
                speed = 1,
                max_range = ability_data.radius * 2,
            }
            ---@diagnostic enable: missing-fields
        end
    end
end

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

local damage_functions = {
    burst = activate_burst_damage,
    punch = activate_punch_damage,
    cure = activate_cure_damage,
    slash = activate_slash_damage,
    rocket_launcher = activate_rocket_launcher,
    -- pavement = function() return end,
    beam_blast = activate_beam_blast,
    discharge_defender = activate_discharge_defender,
    destroyer = activate_destroyer_capsule,
    distractor = activate_distractor_capsule,
    defender = activate_defender_capsule,
    landmine = activate_landmine_deployer,
    poison_capsule = activate_poison_capsule_deployer,
    slowdown_capsule = activate_slowdown_capsule_deployer,
    gun_turret = activate_gun_turret_deployer,
    shotgun = activate_shotgun,
    -- barrier = function() return end,
}

local animation_functions = {
    burst = draw_animation,
    punch = draw_animation,
    cure = draw_animation,
    slash = draw_animation,
    -- rocket_launcher = draw_animation,
    pavement = draw_pavement,
    -- beam_blast = draw_animation,
    -- discharge_defender = draw_animation,
    -- destroyer = draw_animation,
    -- distractor = draw_animation,
    -- defender = draw_animation,
    -- landmine = draw_animation,
    -- poison_capsule = draw_animation,
    -- slowdown_capsule = draw_animation,
    gun_turret = refill_and_repair_turrets,
    -- shotgun = draw_animation,
    barrier = draw_barrier,
}

---@param text string|LocalisedString
---@param player LuaPlayer
---@param offset Vector?
local function draw_upgrade_text(text, player, offset)
    local position = player.position
    if offset then
        position.x = position.x + offset.x
        position.y = position.y + offset.y
    end
    rendering.draw_text({
        text = text,
        surface = player.surface,
        target = position,
        color = player.chat_color,
        time_to_live = 60 * 10,
        scale = 3.5,
        alignment = "center",
    })
end

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

---@param ability_name string
---@param ability_data active_ability_data
---@param player LuaPlayer
local function upgrade_damage(ability_name, ability_data, player)
    ability_data.damage = ability_data.damage * ability_data.damage_multiplier
    local text = {"", { "ability_locale." .. ability_name }, " [lvl ", ability_data.level, "] damage increased to ", ability_data.damage}
    draw_upgrade_text(text, player)
    activate_ability(ability_name, ability_data, player)
end

---@param ability_name string
---@param ability_data active_ability_data
---@param player LuaPlayer
local function upgrade_radius(ability_name, ability_data, player)
    ability_data.radius = ability_data.radius + ability_data.radius_multiplier
    local text = {"", { "ability_locale." .. ability_name }, " [lvl ", ability_data.level, "] radius increased to ", ability_data.radius}
    draw_upgrade_text(text, player)
    activate_ability(ability_name, ability_data, player)
end

---@param ability_name string
---@param ability_data active_ability_data
---@param player LuaPlayer
local function upgrade_cooldown(ability_name, ability_data, player)
    ability_data.cooldown = math.max(1, math.ceil(ability_data.cooldown - ability_data.cooldown_multiplier))
    local text = {"", { "ability_locale." .. ability_name }, " [lvl ", ability_data.level, "] cooldown decreased to ", ability_data.cooldown}
    draw_upgrade_text(text, player)
    activate_ability(ability_name, ability_data, player)
end

local ability_upgrade_functions = {
    ["damage"] = upgrade_damage,
    ["radius"] = upgrade_radius,
    ["cooldown"] = upgrade_cooldown,
}

---@param player LuaPlayer
local function upgrade_random_ability(player)
    local player_data = global.player_data[player.index]
    local abilities = player_data.abilities --[[@as table<string, active_ability_data>]]
    local upgradeable_abilities = {}
    for _, ability in pairs(abilities) do
        local level = ability.level
        if ability.upgrade_order[level] then
            table.insert(upgradeable_abilities, ability.name)
        end
    end
    if #upgradeable_abilities == 0 then
        game.print("no more abilities to upgrade!")
        return
    end
    local ability_name = upgradeable_abilities[math.random(#upgradeable_abilities)]
    local ability_data = abilities[ability_name]
    local upgrade_type = ability_data.upgrade_order[ability_data.level]
    local upgrade = ability_upgrade_functions[upgrade_type]
    if upgrade then
        ability_data.level = ability_data.level + 1
        upgrade(ability_name, ability_data, player)
    end
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
        local text = {"", { "ability_locale." .. ability_name }, " [lvl 1] unlocked!"}
        draw_upgrade_text(text, player, { x = 0, y = 3 })
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
---@return uint64
local function create_kill_counter_rendering(player)
    return rendering.draw_text {
        text = {"", {"counter_locale.kills"}, ": ", "0"},
        surface = player.surface,
        target = player.character,
        target_offset = { x = 0, y = 1 },
        color = { r = 1, g = 1, b = 1 },
        scale = 1.5,
        alignment = "center",
    }
end

local function create_kills_per_minute_counter_rendering(player)
    return rendering.draw_text {
        text = {"", {"counter_locale.kills_per_minute"}, ": [color=", "white", "]", "0", "[/color]"},
        surface = player.surface,
        target = player.character,
        target_offset = { x = 0, y = 2 },
        color = { r = 1, g = 1, b = 1 },
        scale = 1.5,
        alignment = "center",
        use_rich_text = true,
    }
end

---@param player LuaPlayer
local function update_kill_counter(player)
    if not player.character then return end
    local player_index = player.index
    global.kill_counters = global.kill_counters or {}
    global.kill_counters[player_index] = global.kill_counters[player_index] or {
        render_id = create_kill_counter_rendering(player),
        kill_count = 0,
    }
    local kill_counter = global.kill_counters[player_index]
    kill_counter.kill_count = kill_counter.kill_count + 1
    if not rendering.is_valid(kill_counter.render_id) then
        kill_counter.render_id = create_kill_counter_rendering(player)
    end
    local text = {"", {"counter_locale.kills"}, ": ", kill_counter.kill_count}
    rendering.set_text(kill_counter.render_id, text)

    local player_stats = global.statistics[player_index] --[[@type player_statistics]]
    if player_stats then
        player_stats.total.kills = player_stats.total.kills + 1
        player_stats.last_attempt.kills = player_stats.last_attempt.kills + 1
    end
end

local function update_kills_per_minute_counter(player)
    if not player.character then return end
    local player_index = player.index
    local kill_counter = global.kill_counters and global.kill_counters[player_index]
    if not kill_counter then return end
    local start_tick = global.arena_start_tick
    if not start_tick then return end
    global.kills_per_minute_counters = global.kills_per_minute_counters or {}
    global.kills_per_minute_counters[player_index] = global.kills_per_minute_counters[player_index] or {
        render_id = create_kills_per_minute_counter_rendering(player),
    }
    local kills_per_minute_counter = global.kills_per_minute_counters[player_index]
    if not rendering.is_valid(kills_per_minute_counter.render_id) then
        kills_per_minute_counter.render_id = create_kills_per_minute_counter_rendering(player)
    end
    local kills_per_minute = math.min(kill_counter.kill_count, math.floor(kill_counter.kill_count / ((game.tick - start_tick) / 3600)))
    local last_text = rendering.get_text(kills_per_minute_counter.render_id) --[[@as LocalisedString]]
    local last_color = last_text and last_text[4] or "white"
    local last_kpm = last_text and tonumber(last_text[6]) or 0
    local color = kills_per_minute > last_kpm and "green" or kills_per_minute < last_kpm and "red" or last_color
    local text = {"", {"counter_locale.kills_per_minute"}, ": [color=", color, "]", kills_per_minute, "[/color]"}
    rendering.set_text(kills_per_minute_counter.render_id, text)

    local player_stats = global.statistics[player_index] --[[@type player_statistics]]
    if player_stats then
        player_stats.total.top_kills_per_minute = math.max(player_stats.total.top_kills_per_minute, kills_per_minute)
        player_stats.last_attempt.top_kills_per_minute = math.max(player_stats.last_attempt.top_kills_per_minute, kills_per_minute)
    end
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
    if not (player.controller_type == defines.controllers.character) then return end
    -- local player_data = global.player_data[player.index]
    -- local level = player_data.level
    local arena_minutes = global.arena_start_tick and math.floor((game.tick - global.arena_start_tick) / 60 / 60) or 0
    local enemy_name = "small-biter"
    local chance = 15 / 100
    if arena_minutes >= 2 then
        if math.random() < (chance - 1/100) then
            enemy_name = "small-spitter"
        end
    end
    if arena_minutes >= 3 then
        if math.random() < (chance - 2/100) then
            enemy_name = "medium-biter"
        end
    end
    if arena_minutes >= 4 then
        if math.random() < (chance - 3/100) then
            enemy_name = "medium-spitter"
        end
    end
    if arena_minutes >= 5 then
        if math.random() < (chance - 4/100) then
            enemy_name = "small-worm-turret"
        end
    end
    if arena_minutes >= 6 then
        if math.random() < (chance - 5/100) then
            enemy_name = "big-biter"
        end
    end
    if arena_minutes >= 7 then
        if math.random() < (chance - 6/100) then
            enemy_name = "big-spitter"
        end
    end
    if arena_minutes >= 8 then
        if math.random() < (chance - 7/100) then
            enemy_name = "medium-worm-turret"
        end
    end
    if arena_minutes >= 9 then
        if math.random() < (chance - 8/100) then
            enemy_name = "behemoth-biter"
        end
    end
    if arena_minutes >= 10 then
        if math.random() < (chance - 9/100) then
            enemy_name = "behemoth-spitter"
        end
    end
    if arena_minutes >= 12 then
        if math.random() < (chance - 10/100) then
            enemy_name = "big-worm-turret"
        end
    end
    if arena_minutes >= 14 then
        if math.random() < (chance - 11/100) then
            enemy_name = "behemoth-worm-turret"
        end
    end
    if arena_minutes >= 15 then
        enemy_name = "behemoth-worm-turret"
    end
    local radius = math.random(25, 50)
    local arena_clock = (game.tick - global.arena_start_tick)
    if arena_clock > global.game_length then
        radius = math.random(5, 75)
    end
    local position = get_random_position_on_circumference(player.position, radius)
    position = player.surface.find_non_colliding_position(enemy_name, position, 100, 1) or position
    spawn_new_enemy(player.surface, position, enemy_name, player)
end

---@param event EventData.on_player_died
local function on_player_died(event)
    game.set_game_state {
        game_finished = false,
    }
    local player = game.get_player(event.player_index)
    if not player then return end
    local ticks = (player and (player.surface.name == "lobby") and (60 * 5)) or (60 * 8)
    player.ticks_to_respawn = ticks

    if global.game_state == "arena" then
        local player_stats = global.statistics[player.index] --[[@type player_statistics]]
        if player_stats then
            player_stats.total.deaths = player_stats.total.deaths + 1
            player_stats.last_attempt.deaths = player_stats.last_attempt.deaths + 1
        end
        global.remaining_lives = global.remaining_lives or {}
        global.remaining_lives[player.index] = global.remaining_lives[player.index] or 1
        local text = {"", "Engineer down! ", global.remaining_lives[player.index] - 1, " lives remaining"}

        if global.arena_start_tick - game.tick >= global.game_length then
            text = {"", "Victory lap!"}
            player_stats.total.victories = player_stats.total.victories + 1
            player_stats.last_attempt.victories = player_stats.last_attempt.victories + 1
            global.remaining_lives[player.index] = 0
        end

        draw_upgrade_text(text, player, { x = 0, y = 3 })
    end
end

---@param position_1 MapPosition
---@param position_2 MapPosition
---@return number
local function distance(position_1, position_2)
    local x = position_1.x - position_2.x
    local y = position_1.y - position_2.y
    return math.sqrt(x * x + y * y)
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
        if damage_type.name == "fire" then
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
                entity.health = entity.prototype.max_health
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
        local technology_upgrades = {
            ["physical-projectile-damage-"] = true,
            ["energy-weapons-damage-"] = true,
            ["stronger-explosives-"] = true,
            ["refined-flammables-"] = true,
            -- ["weapon-shooting-speed-"] = true,
        }
        local force = game.forces.player
        local max_tech_level = math.ceil(level_threshold / 5)
        for i = 1, max_tech_level do
            for name, _ in pairs(technology_upgrades) do
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
        for i = 1, max_tech_level / 5 do
            local tech_name = "follower-robot-count-" .. i
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
    if player and player.character then
        if not (player.surface.name == "arena") then return end
        local player_data = global.player_data[player.index]
        -- player_data.exp = player_data.exp + (entity.prototype.max_health / 15 or 1)
        player_data.exp = player_data.exp + 1
        if player_data.exp >= 3 * player_data.level then
            player_data.exp = 0
            player_data.level = player_data.level + 1
            local level = player_data.level
            upgrade_random_ability(player)
            local shimmer_data = { radius = 2, level = 1, cooldown = 0, damage = 0 }
            draw_animation("shimmer", shimmer_data, player)
            if level % 7 == 0 then
                unlock_random_ability(player)
            end
            global.remaining_lives = global.remaining_lives or {}
            global.remaining_lives[player.index] = global.remaining_lives[player.index] or 1
            if level % 33 == 0 then
                global.remaining_lives[player.index] = global.remaining_lives[player.index] + 1
                draw_upgrade_text({"", "Level up! ", global.remaining_lives[player.index] - 1, " lives remaining"}, player, { x = 0, y = 3 })
            end
            if level % 8 == 0 then
                upgrade_damage_bonuses(level)
            end
        end
        update_kill_counter(player)
        -- local enemy_name = entity.name
        -- local radius = math.random(25, 55)
        -- local position = get_random_position_on_circumference(player.position, radius)
        -- position = player.surface.find_non_colliding_position(enemy_name, position, 100, 1) or position
        -- spawn_new_enemy(player.surface, position, enemy_name, player)
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
    player.character_running_speed_modifier = 0.33
    player.character_maximum_following_robot_count_bonus = 500
    global.remaining_lives = global.remaining_lives or {}
    global.remaining_lives[player_index] = global.remaining_lives[player_index] or 0
    global.remaining_lives[player_index] = global.remaining_lives[player_index] - 1
    if global.remaining_lives[player_index] < 1 then
        local character = player.character
        player.set_controller{type = defines.controllers.spectator}
        if character then
            character.destroy()
        end
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
            global.arena_start_tick = game.tick
            local enemies = game.surfaces.arena.find_entities_filtered{
                force = "enemy",
            }
            for _, enemy in pairs(enemies) do
                enemy.destroy()
            end
            for _, player in pairs(players) do
                local position = game.get_surface("arena").find_non_colliding_position("character", {x = 0, y = 0}, 100, 1)
                position = position or {x = player.index * 2, y = 0}
                player.teleport(position, "arena")
                player.character_maximum_following_robot_count_bonus = 500
                player.character_running_speed_modifier = 0.33
                new_attempt_stats_reset(player.index)
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

---@param event EventData.on_tick
local function on_tick(event)

    if not script.level and script.level.mod_name == "asher_sky" then return end
    global.game_state = global.game_state or "lobby"
    local connected_players = game.connected_players

    -- lobby mode --
    if global.game_state == "lobby" then

        local lobby_surface = game.surfaces.lobby
        initialize_lobby()
        for _, player in pairs(connected_players) do
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
        if game.tick % (60 * 25) == 0 then
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
        if game.tick % (60 * 2) == 0 then
            global.player_chat_colors = global.player_chat_colors or {}
            for _, player in pairs(game.players) do
                local current_color = player.chat_color
                local previous_color = global.player_chat_colors[player.index]
                if previous_color then
                    if not (current_color.r == previous_color.r and current_color.g == previous_color.g and current_color.b == previous_color.b) then
                        update_statistics()
                    end
                end
                global.player_chat_colors[player.index] = current_color
            end
        end
    end

    -- lobby and arena --

    for _, player in pairs(connected_players) do
        if not player.character then break end
        global.player_data[player.index] = global.player_data[player.index] or initialize_player_data(player)
        local player_data = global.player_data[player.index]
        for ability_name, ability_data in pairs(player_data.abilities) do
            if (((event.tick + (player.index * 25)) % ability_data.cooldown) == 0) then
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
            player.character.damage(healing_player.damage, "enemy", "impact")
        end
        if healing_player.final_tick <= event.tick then
            global.healing_players[id] = nil
        end
    end
    for id, flamethrower_target in pairs(global.flamethrower_targets) do
        local player = flamethrower_target.player
        local final_tick = flamethrower_target.final_tick
        if player.character then
            local position = flamethrower_target.position
            activate_flamethrower(player, position)
        end
        if final_tick <= event.tick then
            global.flamethrower_targets[id] = nil
        end
    end

    -- arena mode --

    if global.game_state == "arena" then
        local difficulties = {
            easy = 40,
            normal = 25,
            hard = 10,
        }
        local balance = difficulties[global.lobby_options.difficulty]
        if game.tick % balance == 0 then
            for _, player in pairs(connected_players) do
                update_kills_per_minute_counter(player)
                spawn_level_appropriate_enemy(player)
            end
        end
        for _, player in pairs(connected_players) do
            local position = player.position
            global.previous_positions = global.previous_positions or {}
            global.previous_positions[player.index] = global.previous_positions[player.index] or position
            local previous_position = global.previous_positions[player.index]
            if position.x == previous_position.x and position.y == previous_position.y then
                local chance = 75/100
                if global.arena_start_tick - game.tick <= 60 * 60 * 0.75 then
                    chance = 15/100
                end
                if math.random() < chance then
                    spawn_level_appropriate_enemy(player)
                end
            end
            global.previous_positions[player.index] = position
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
            end
            global.game_state = "lobby"
            global.arena_start_tick = nil
            global.kill_counters = nil
            global.remaining_lives = nil
            global.kills_per_minute_counters = nil
            game.forces.player.reset()
            randomize_starting_abilities()
            update_lobby_text()
            update_statistics()
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

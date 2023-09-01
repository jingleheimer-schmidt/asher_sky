
require("util")
local constants = require("__asher_sky__/constants")
local tile_tiers_by_name = constants.tile_tiers_by_name
local tile_tiers_by_order = constants.tile_tiers_by_order
local raw_abilities_data = constants.ability_data
local aoe_damage_modifier = constants.aoe_damage_modifier

local general_util = require("general_util")
local get_position_on_circumference = general_util.get_position_on_circumference
local direction_to_angle = general_util.direction_to_angle
local opposite_direction = general_util.opposite_direction
local degrees_to_radians = general_util.degrees_to_radians

local luarendering_util = require("luarendering_util")
local draw_animation = luarendering_util.draw_animation

local enemy_util = require("enemy_util")
local find_nearest_enemy = enemy_util.find_nearest_enemy
local get_enemies_in_radius = enemy_util.get_enemies_in_radius
local damage_enemies_in_radius = enemy_util.damage_enemies_in_radius

local ability_util = require("ability_util")
local activate_flamethrower = ability_util.activate_flamethrower
local register_burn_zone = ability_util.register_burn_zone
local create_flamethrower_target = ability_util.create_flamethrower_target
local register_damage_zone = ability_util.register_damage_zone
local register_laser_beam_target = ability_util.register_laser_beam_target
local create_laser_beam = ability_util.create_laser_beam
local register_poison_zone = ability_util.register_poison_zone
local refill_infividual_turret_ammo = ability_util.refill_infividual_turret_ammo
local refill_existing_turrets = ability_util.refill_nearby_turrets

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
    if discharge_defender and discharge_defender.valid then
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
    if destroyer and destroyer.valid then
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
        if distractor and distractor.valid then
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
    if defender and defender.valid then
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
    if landmine and landmine.valid then
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
            if turret and turret.valid then
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

return {
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
    ability_functions = ability_functions,
}
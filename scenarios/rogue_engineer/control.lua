
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

---@param center MapPosition
---@param radius number
---@param angle number
---@return MapPosition
local function get_position_on_circumference(center, radius, angle)
    local x = center.x + radius * math.cos(angle)
    local y = center.y + radius * math.sin(angle)
    return { x = x, y = y }
end

---@param center MapPosition
---@param radius number
---@return MapPosition
local function get_random_position_on_circumference(center, radius)
    local angle = math.random() * 2 * math.pi
    return get_position_on_circumference(center, radius, angle)
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
        pavement = true,
        beam_chain = true,
        discharge_defender = true,
        destroyer = true,
        landmine = true,
    }
    global.available_starting_abilities = {
        burst = true,
        punch = true,
        -- cure = true,
        slash = true,
        rocket_launcher = true,
        -- pavement = true,
        -- beam_chain = true,
        -- discharge_defender = true,
        destroyer = true,
        -- landmine = true,
    }
    global.default_abilities = {
        ability_1 = "landmine",
        ability_2 = "slash",
        ability_3 = "rocket_launcher",
    }
    global.statistics = {}
end

local function random_table_value(table_param)
    local keys = {}
    for key, _ in pairs(table_param) do
        table.insert(keys, key)
    end
    return table_param[keys[math.random(#keys)]]
end

local function random_table_key(table_param)
    local keys = {}
    for key, _ in pairs(table_param) do
        table.insert(keys, key)
    end
    return keys[math.random(#keys)]
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
    local tile_tier = tile_tiers_by_name[tile_name]
    tile_tier = math.min(ability_data.level, (tile_tier or 0))
    local next_tile_name = tile_tiers_by_order[tile_tier + 1]
    if not next_tile_name then return end
    local tiles = {
        {name = next_tile_name, position = {x = position.x, y = position.y}}
    }
    if ability_data.radius > 1 then
        local radius = ability_data.radius - 1
        for x = -radius, radius do
            for y = -radius, radius do
                if x ~= 0 or y ~= 0 then
                    table.insert(tiles, {name = next_tile_name, position = {x = position.x + x, y = position.y + y}})
                end
            end
        end
    end
    surface.set_tiles(tiles)
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
---@param damage float
---@param position MapPosition
---@param surface LuaSurface
---@param player LuaPlayer
local function damage_enemies_in_radius(radius, damage, position, surface, player)
    local character = player.character
    if not character then return end
    local enemies = surface.find_entities_filtered{
        position = position,
        radius = radius,
        force = "enemy",
        type = "unit",
    }
    for _, enemy in pairs(enemies) do
        enemy.damage(damage, player.force, "impact", character)
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
    ---@diagnostic disable: missing-fields
    local rocket = surface.create_entity{
        name = "rocket",
        position = player.position,
        direction = player.character.direction,
        force = player.force,
        target = enemy,
        source = player.character,
        speed = 1/10,
        max_range = ability_data.radius * 20,
        player = player,
    }
    ---@diagnostic enable: missing-fields
end

---@param from MapPosition
---@param to MapPosition
---@return Vector
local function offset_vector(from, to)
    return { x = to.x - from.x, y = to.y - from.y }
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

---@param surface LuaSurface
---@param position MapPosition
---@param radius integer
---@return LuaEntity[]
local function get_enemies_in_radius(surface, position, radius)
    return surface.find_entities_filtered{
        position = position,
        radius = radius,
        force = "enemy",
        type = "unit",
    }
end

---@param ability_data active_ability_data
---@param player LuaPlayer
local function activate_beam_chain(ability_data, player)
    local surface = player.surface
    local player_position = player.position
    local radius = ability_data.radius
    local enemy_1 = surface.find_nearest_enemy{
        position = player_position,
        max_distance = radius,
        force = player.force,
    }
    if not enemy_1 then return end
    create_laser_beam(surface, player_position, enemy_1, player)
    local nearby_enemies_1 = get_enemies_in_radius(surface, enemy_1.position, radius)
    for _, enemy_2 in pairs(nearby_enemies_1) do
        create_laser_beam(surface, enemy_1.position, enemy_2, player)
        -- local nearby_enemies_2 = get_enemies_in_radius(surface, enemy_2.position, radius / 5)
        -- for _, enemy_3 in pairs(nearby_enemies_2) do
        --     create_laser_beam(surface, enemy_2.position, enemy_3, player)
        -- end
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
local function activate_landmine_deployer(ability_data, player)
    local surface = player.surface
    local radius = math.random(0, ability_data.radius)
    local position = get_position_on_circumference(player.position, radius, math.random() * 2 * math.pi)
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

local damage_functions = {
    burst = activate_burst_damage,
    punch = activate_punch_damage,
    cure = activate_cure_damage,
    slash = activate_slash_damage,
    rocket_launcher = activate_rocket_launcher,
    -- pavement = function() return end,
    beam_chain = activate_beam_chain,
    discharge_defender = activate_discharge_defender,
    destroyer = activate_destroyer_capsule,
    landmine = activate_landmine_deployer,
}

local animation_functions = {
    burst = draw_animation,
    punch = draw_animation,
    cure = draw_animation,
    slash = draw_animation,
    -- rocket_launcher = draw_animation,
    pavement = draw_pavement,
    -- beam_chain = draw_animation,
    -- discharge_defender = draw_animation,
    -- destroyer = draw_animation,
    -- landmine = draw_animation,
}

---@param text string|LocalisedString
---@param player LuaPlayer
---@param offset Vector?
local function draw_upgrade_text(text, player, offset)
    -- local position = get_random_position_on_circumference(player.position, 5)
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
        -- draw_on_ground = true,
        alignment = "center",
    })
end

---@param ability_name string
---@param ability_data active_ability_data
---@param player LuaPlayer
local function upgrade_damage(ability_name, ability_data, player)
    ability_data.damage = ability_data.damage * ability_data.damage_multiplier
    local text = {"", "Level up! ", { "ability_locale." .. ability_name }, " damage is now ", ability_data.damage, " "}
    draw_upgrade_text(text, player)
end

---@param ability_name string
---@param ability_data active_ability_data
---@param player LuaPlayer
local function upgrade_radius(ability_name, ability_data, player)
    ability_data.radius = ability_data.radius + ability_data.radius_multiplier
    local text = {"", "Level up! ", { "ability_locale." .. ability_name }, " radius is now ", ability_data.radius, " "}
    draw_upgrade_text(text, player)
end

---@param ability_name string
---@param ability_data active_ability_data
---@param player LuaPlayer
local function upgrade_cooldown(ability_name, ability_data, player)
    ability_data.cooldown = math.max(1, math.ceil(ability_data.cooldown - ability_data.cooldown_multiplier))
    local text = {"", "Level up! ", { "ability_locale." .. ability_name }, " cooldown is now ", ability_data.cooldown, " "}
    draw_upgrade_text(text, player)
end

local ability_upgrade_functions = {
    ["damage"] = upgrade_damage,
    ["radius"] = upgrade_radius,
    ["cooldown"] = upgrade_cooldown,
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
        upgrade(ability_name, ability_data, player)
        ability_data.level = ability_data.level + 1
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
        local text = {"", "Ability unlocked! ", { "ability_locale." .. ability_name }, " is now level 1."}
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
        text = "Kills: 0",
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
        text = "Kills per minute: [color=white]0[/color]",
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
    rendering.set_text(kill_counter.render_id, "Kills: " .. kill_counter.kill_count)

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
    local previous_text = rendering.get_text(kills_per_minute_counter.render_id) or ""
    local previous_kills_per_minute = tonumber(previous_text:match("%d+"))
    local color = previous_text:match("%[color=(%w+)%]")
    if kills_per_minute > previous_kills_per_minute then
        color = "green"
    elseif kills_per_minute < previous_kills_per_minute then
        color = "red"
    end
    rendering.set_text(kills_per_minute_counter.render_id, "Kills per minute: [color=" .. color .. "]" .. kills_per_minute .. "[/color]")

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
    local level = global.arena_start_tick and math.floor((game.tick - global.arena_start_tick) / 60 / 60) or 0
    local enemy_name = "small-biter"
    local chance = 15 / 100
    if level >= 2 then
        if math.random() < (chance - 1/100) then
            enemy_name = "small-spitter"
        end
    end
    if level >= 4 then
        if math.random() < (chance - 2/100) then
            enemy_name = "medium-biter"
        end
    end
    if level >= 6 then
        if math.random() < (chance - 3/100) then
            enemy_name = "medium-spitter"
        end
    end
    if level >= 8 then
        if math.random() < (chance - 4/100) then
            enemy_name = "small-worm-turret"
        end
    end
    if level >= 10 then
        if math.random() < (chance - 5/100) then
            enemy_name = "big-biter"
        end
    end
    if level >= 12 then
        if math.random() < (chance - 6/100) then
            enemy_name = "big-spitter"
        end
    end
    if level >= 14 then
        if math.random() < (chance - 7/100) then
            enemy_name = "medium-worm-turret"
        end
    end
    if level >=16 then
        if math.random() < (chance - 8/100) then
            enemy_name = "behemoth-biter"
        end
    end
    if level >= 18 then
        if math.random() < (chance - 9/100) then
            enemy_name = "behemoth-spitter"
        end
    end
    if level >= 20 then
        if math.random() < (chance - 10/100) then
            enemy_name = "big-worm-turret"
        end
    end
    if level >= 22 then
        if math.random() < (chance - 11/100) then
            enemy_name = "behemoth-worm-turret"
        end
    end
    if level >= 25 then
        enemy_name = "behemoth-worm-turret"
    end
    local radius = math.random(30, 50)
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
        local text = {"", "Engineer down! ", global.remaining_lives[player.index] - 1, " lives remaining"}

        if global.arena_start_tick - game.tick >= 60 * 60 * 25 then
            text = {"", "Victory lap!"}
            player_stats.total.victories = player_stats.total.victories + 1
            player_stats.last_attempt.victories = player_stats.last_attempt.victories + 1
            global.remaining_lives[player.index] = 0
        end

        draw_upgrade_text(text, player, { x = 0, y = 3 })
    end
end

script.on_event(defines.events.on_player_died, on_player_died)

---@param event EventData.on_entity_damaged
local function on_entity_damaged(event)
    local entity = event.entity
    local surface = entity.surface
    if surface.name == "lobby" then
        if entity.type == "character" then
            -- entity.health = entity.health + event.final_damage_amount
            entity.damage( - event.final_damage_amount, entity.force, "impact")
        end
    end
    local damage = math.ceil(event.final_damage_amount)
    local flying_text = ((damage > 0) and ("-" .. damage)) or ("+" .. damage)
    local color = ((damage > 0 )and {r = 1, g = 0, b = 0}) or {r = 0, g = 1, b = 0}
    surface.create_entity{
        name = "flying-text",
        position = entity.position,
        text = flying_text,
        color = color,
    }
end

script.on_event(defines.events.on_entity_damaged, on_entity_damaged)

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
        }
        local force = game.forces.player
        local max_tech_level = math.ceil(level_threshold / 5)
        for i = 1, max_tech_level do
            for name, _ in pairs(technology_upgrades) do
                local tech_name = name .. math.min(i, 7)
                local prerequisites = force.technologies[tech_name].prerequisites
                for _, prerequisite in pairs(prerequisites) do
                    force.technologies[prerequisite.name].researched = true
                end
                force.technologies[tech_name].researched = true
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
    local cause = event.cause
    local cause_type = cause and cause.type
    local player = cause and cause_type == "character" and cause.player or nil
    if cause and cause_type == "combat-robot" then
        player = cause.combat_robot_owner and cause.combat_robot_owner.player
    end
    if cause and cause_type == "land-mine" and cause.last_user then
        player = cause.last_user --[[@as LuaPlayer]]
    end
    if player and player.character then
        local player_data = global.player_data[player.index]
        -- player_data.exp = player_data.exp + (entity.prototype.max_health / 15 or 1)
        player_data.exp = player_data.exp + 1
        if player_data.exp >= 3 * player_data.level then
            player_data.exp = 0
            player_data.level = player_data.level + 1
            upgrade_random_ability(player)
            local shimmer_data = { radius = 2, level = 1, cooldown = 0, damage = 0 }
            draw_animation("shimmer", shimmer_data, player)
            if player_data.level % 5 == 0 then
                unlock_random_ability(player)
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
        spawn_level_appropriate_enemy(player)
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
    global.remaining_lives[player_index] = global.remaining_lives[player_index] or 2
    global.remaining_lives[player_index] = global.remaining_lives[player_index] - 1
    local lives = global.remaining_lives[player_index]
    if lives < 1 then
        player.set_controller{type = defines.controllers.spectator}
    end
end

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
    global.statistics[player.index] = global.statistics[player.index] or {
        total = { --[[@type player_statistics_data]]
            kills = 0,
            deaths = 0,
            damage_dealt = 0,
            damage_taken = 0,
            damage_healed = 0,
            attempts = 0,
            victories = 0,
            top_kills_per_minute = 0,
        },
        last_attempt = { --[[@type player_statistics_data]]
            kills = 0,
            deaths = 0,
            damage_dealt = 0,
            damage_taken = 0,
            damage_healed = 0,
            attempts = 0,
            victories = 0,
            top_kills_per_minute = 0,
        },
    }
end

---@class player_statistics_data
---@field kills uint
---@field deaths uint
---@field damage_dealt uint
---@field damage_taken uint
---@field damage_healed uint
---@field attempts uint
---@field victories uint
---@field top_kills_per_minute uint

---@class player_statistics
---@field total player_statistics_data
---@field last_attempt player_statistics_data

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
                enemy.die()
            end
            for _, player in pairs(players) do
                local position = game.get_surface("arena").find_non_colliding_position("character", {x = 0, y = 0}, 100, 1)
                position = position or {x = 0, y = 0}
                player.teleport(position, "arena")
                player.character_maximum_following_robot_count_bonus = 500
                player.character_running_speed_modifier = 0.33
                local player_stats = global.statistics[player.index] --[[@type player_statistics]]
                if player_stats then
                    player_stats.total.attempts = player_stats.total.attempts + 1
                    player_stats.last_attempt.attempts = 1
                    player_stats.last_attempt.kills = 0
                    player_stats.last_attempt.deaths = 0
                    player_stats.last_attempt.damage_dealt = 0
                    player_stats.last_attempt.damage_taken = 0
                    player_stats.last_attempt.damage_healed = 0
                    player_stats.last_attempt.top_kills_per_minute = 0
                    player_stats.last_attempt.victories = 0
                end
            end
        end
    end
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

local function update_statistics()
    local players = game.players
    local statistics = global.statistics --[[@type table<uint, player_statistics>]]
    local render_ids = global.statistics_render_ids
    local player_total_scores = {}
    local player_last_scores = {}
    for _, player in pairs(players) do
        local player_index = player.index
        local player_stats = statistics[player_index]
        local total_score = (player_stats.total.kills / (player_stats.total.deaths + 1)) * (player_stats.total.victories + 1 / (player_stats.total.attempts + 1))
        player_total_scores[player_index] = total_score
        local last_score = (player_stats.last_attempt.kills / (player_stats.last_attempt.deaths + 1)) * (player_stats.last_attempt.victories + 1 / (player_stats.last_attempt.attempts + 1))
        player_last_scores[player_index] = last_score
    end
    local sorted_total_scores = {}
    local sorted_last_scores = {}
    for player_index, score in pairs(player_total_scores) do
        table.insert(sorted_total_scores, {player_index = player_index, score = score})
    end
    for player_index, score in pairs(player_last_scores) do
        table.insert(sorted_last_scores, {player_index = player_index, score = score})
    end
    table.sort(sorted_total_scores, function(a, b) return a.score > b.score end)
    table.sort(sorted_last_scores, function(a, b) return a.score > b.score end)
    local player_1 = sorted_total_scores[1] and sorted_total_scores[1].player_index
    local player_2 = sorted_total_scores[2] and sorted_total_scores[2].player_index
    local player_3 = sorted_total_scores[3] and sorted_total_scores[3].player_index

    local player_1_stats = statistics[player_1]
    local player_2_stats = statistics[player_2]
    local player_3_stats = statistics[player_3]

    if player_1 then
        for name, render_id in pairs(render_ids) do
            if name:find("player_1") and name:find("title") then
                if rendering.is_valid(render_id) then
                    rendering.set_color(render_id, players[player_1].chat_color)
                end
            end
        end
        rendering.set_text(render_ids.player_1_name, players[player_1].name)
        rendering.set_color(render_ids.player_1_name, players[player_1].chat_color)
        rendering.set_text(render_ids.player_1_overall_score_total_value, sorted_total_scores[player_1] and math.ceil(sorted_total_scores[player_1].score))
        rendering.set_text(render_ids.player_1_overall_score_last_value, player_last_scores[player_1] and math.ceil(player_last_scores[player_1]))
        rendering.set_text(render_ids.player_1_total_kills_total_value, player_1_stats.total.kills)
        rendering.set_text(render_ids.player_1_total_kills_last_value, player_1_stats.last_attempt.kills)
        rendering.set_text(render_ids.player_1_total_deaths_total_value, player_1_stats.total.deaths)
        rendering.set_text(render_ids.player_1_total_deaths_last_value, player_1_stats.last_attempt.deaths)
        rendering.set_text(render_ids.player_1_top_kills_per_minute_total_value, player_1_stats.total.top_kills_per_minute)
        rendering.set_text(render_ids.player_1_top_kills_per_minute_last_value, player_1_stats.last_attempt.top_kills_per_minute)
        rendering.set_text(render_ids.player_1_arena_attempts_total_value, player_1_stats.total.attempts)
        rendering.set_text(render_ids.player_1_arena_attempts_last_value, player_1_stats.last_attempt.attempts)
        rendering.set_text(render_ids.player_1_arena_victories_total_value, player_1_stats.total.victories)
        rendering.set_text(render_ids.player_1_arena_victories_last_value, player_1_stats.last_attempt.victories)
    end
    if player_2 then
        for name, render_id in pairs(render_ids) do
            if name:find("player_2") and name:find("title") then
                if rendering.is_valid(render_id) then
                    rendering.set_color(render_id, players[player_2].chat_color)
                end
            end
        end
        rendering.set_text(render_ids.player_2_name, players[player_2].name)
        rendering.set_color(render_ids.player_2_name, players[player_2].chat_color)
        rendering.set_text(render_ids.player_2_overall_score_total_value, sorted_total_scores[player_2] and math.ceil(sorted_total_scores[player_2].score))
        rendering.set_text(render_ids.player_2_overall_score_last_value, player_last_scores[player_2] and math.ceil(player_last_scores[player_2]))
        rendering.set_text(render_ids.player_2_total_kills_total_value, player_2_stats.total.kills)
        rendering.set_text(render_ids.player_2_total_kills_last_value, player_2_stats.last_attempt.kills)
        rendering.set_text(render_ids.player_2_total_deaths_total_value, player_2_stats.total.deaths)
        rendering.set_text(render_ids.player_2_total_deaths_last_value, player_2_stats.last_attempt.deaths)
        rendering.set_text(render_ids.player_2_top_kills_per_minute_total_value, player_2_stats.total.top_kills_per_minute)
        rendering.set_text(render_ids.player_2_top_kills_per_minute_last_value, player_2_stats.last_attempt.top_kills_per_minute)
        rendering.set_text(render_ids.player_2_arena_attempts_total_value, player_2_stats.total.attempts)
        rendering.set_text(render_ids.player_2_arena_attempts_last_value, player_2_stats.last_attempt.attempts)
        rendering.set_text(render_ids.player_2_arena_victories_total_value, player_2_stats.total.victories)
        rendering.set_text(render_ids.player_2_arena_victories_last_value, player_2_stats.last_attempt.victories)
    end
    if player_3 then
        for name, render_id in pairs(render_ids) do
            if name:find("player_3") and name:find("title") then
                if rendering.is_valid(render_id) then
                    rendering.set_color(render_id, players[player_3].chat_color)
                end
            end
        end
        rendering.set_text(render_ids.player_3_name, players[player_3].name)
        rendering.set_color(render_ids.player_3_name, players[player_3].chat_color)
        rendering.set_text(render_ids.player_3_overall_score_total_value, sorted_total_scores[player_3] and math.ceil(sorted_total_scores[player_3].score))
        rendering.set_text(render_ids.player_3_overall_score_last_value, player_last_scores[player_3] and math.ceil(player_last_scores[player_3]))
        rendering.set_text(render_ids.player_3_total_kills_total_value, player_3_stats.total.kills)
        rendering.set_text(render_ids.player_3_total_kills_last_value, player_3_stats.last_attempt.kills)
        rendering.set_text(render_ids.player_3_total_deaths_total_value, player_3_stats.total.deaths)
        rendering.set_text(render_ids.player_3_total_deaths_last_value, player_3_stats.last_attempt.deaths)
        rendering.set_text(render_ids.player_3_top_kills_per_minute_total_value, player_3_stats.total.top_kills_per_minute)
        rendering.set_text(render_ids.player_3_top_kills_per_minute_last_value, player_3_stats.last_attempt.top_kills_per_minute)
        rendering.set_text(render_ids.player_3_arena_attempts_total_value, player_3_stats.total.attempts)
        rendering.set_text(render_ids.player_3_arena_attempts_last_value, player_3_stats.last_attempt.attempts)
        rendering.set_text(render_ids.player_3_arena_victories_total_value, player_3_stats.total.victories)
        rendering.set_text(render_ids.player_3_arena_victories_last_value, player_3_stats.last_attempt.victories)
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

script.on_event(defines.events.on_entity_color_changed, on_entity_color_changed)

local function initialize_statistics()

    -- idea: sort all the players by their "score", maybe some addition of their stats, and the populate predefined slots for rendering the statistics text with the top 3 or so players. since idk how to make line breaks, and i'll probably need to make a new rendering for each line of text.

    local statistics = global.statistics
    local render_ids = global.statistics_render_ids
    local lobby_surface = game.surfaces.lobby
    local stat_title_x = -40
    local stat_title_y = -12
    if not render_ids then
        global.statistics_render_ids = {
            title = rendering.draw_text{
                text = "Statistics",
                surface = lobby_surface,
                target = {x = stat_title_x + 7.5, y = stat_title_y - 4},
                color = {r = 1, g = 1, b = 1},
                alignment = "center",
                scale = 4,
            },
            title_total = rendering.draw_text{
                text = "Total",
                surface = lobby_surface,
                target = {x = stat_title_x + 10, y = stat_title_y + 23},
                color = {r = 1, g = 1, b = 1},
                alignment = "right",
                scale = 2,
            },
            title_last = rendering.draw_text{
                text = "Last",
                surface = lobby_surface,
                target = {x = stat_title_x + 15, y = stat_title_y + 23},
                color = {r = 1, g = 1, b = 1},
                alignment = "right",
                scale = 2,
            },
            player_1_name = rendering.draw_text{
                text = "Player 1",
                surface = lobby_surface,
                target = {x = stat_title_x, y = stat_title_y - 0},
                color = {r = 1, g = 1, b = 1},
                alignment = "left",
                vertical_alignment = "middle",
                scale = 4,
            },
            player_1_overall_score_title = rendering.draw_text{
                text = "Overall Score:",
                surface = lobby_surface,
                target = {x = stat_title_x, y = stat_title_y + 1},
                color = {r = 1, g = 1, b = 1},
                alignment = "left",
                scale = 2,
            },
            player_1_overall_score_total_value = rendering.draw_text{
                text = "0",
                surface = lobby_surface,
                target = {x = stat_title_x + 10, y = stat_title_y + 1},
                color = {r = 1, g = 1, b = 1},
                alignment = "right",
                scale = 2,
            },
            player_1_overall_score_last_value = rendering.draw_text{
                text = "0",
                surface = lobby_surface,
                target = {x = stat_title_x + 15, y = stat_title_y + 1},
                color = {r = 1, g = 1, b = 1},
                alignment = "right",
                scale = 2,
            },
            player_1_total_kills_title = rendering.draw_text{
                text = "Arena Kills:",
                surface = lobby_surface,
                target = {x = stat_title_x, y = stat_title_y + 2},
                color = {r = 1, g = 1, b = 1},
                alignment = "left",
                scale = 2,
            },
            player_1_total_kills_total_value = rendering.draw_text{
                text = "0",
                surface = lobby_surface,
                target = {x = stat_title_x + 10, y = stat_title_y + 2},
                color = {r = 1, g = 1, b = 1},
                alignment = "right",
                scale = 2,
            },
            player_1_total_kills_last_value = rendering.draw_text{
                text = "0",
                surface = lobby_surface,
                target = {x = stat_title_x + 15, y = stat_title_y + 2},
                color = {r = 1, g = 1, b = 1},
                alignment = "right",
                scale = 2,
            },
            player_1_total_deaths_title = rendering.draw_text{
                text = "Arena Deaths:",
                surface = lobby_surface,
                target = {x = stat_title_x, y = stat_title_y + 3},
                color = {r = 1, g = 1, b = 1},
                alignment = "left",
                scale = 2,
            },
            player_1_total_deaths_total_value = rendering.draw_text{
                text = "0",
                surface = lobby_surface,
                target = {x = stat_title_x + 10, y = stat_title_y + 3},
                color = {r = 1, g = 1, b = 1},
                alignment = "right",
                scale = 2,
            },
            player_1_total_deaths_last_value = rendering.draw_text{
                text = "0",
                surface = lobby_surface,
                target = {x = stat_title_x + 15, y = stat_title_y + 3},
                color = {r = 1, g = 1, b = 1},
                alignment = "right",
                scale = 2,
            },
            player_1_top_kills_per_minute_title = rendering.draw_text{
                text = "Top Kills/Minute:",
                surface = lobby_surface,
                target = {x = stat_title_x, y = stat_title_y + 4},
                color = {r = 1, g = 1, b = 1},
                alignment = "left",
                scale = 2,
            },
            player_1_top_kills_per_minute_total_value = rendering.draw_text{
                text = "0",
                surface = lobby_surface,
                target = {x = stat_title_x + 10, y = stat_title_y + 4},
                color = {r = 1, g = 1, b = 1},
                alignment = "right",
                scale = 2,
            },
            player_1_top_kills_per_minute_last_value = rendering.draw_text{
                text = "0",
                surface = lobby_surface,
                target = {x = stat_title_x + 15, y = stat_title_y + 4},
                color = {r = 1, g = 1, b = 1},
                alignment = "right",
                scale = 2,
            },
            player_1_arena_attempts_title = rendering.draw_text{
                text = "Arena Attempts:",
                surface = lobby_surface,
                target = {x = stat_title_x, y = stat_title_y + 5},
                color = {r = 1, g = 1, b = 1},
                alignment = "left",
                scale = 2,
            },
            player_1_arena_attempts_total_value = rendering.draw_text{
                text = "0",
                surface = lobby_surface,
                target = {x = stat_title_x + 10, y = stat_title_y + 5},
                color = {r = 1, g = 1, b = 1},
                alignment = "right",
                scale = 2,
            },
            player_1_arena_attempts_last_value = rendering.draw_text{
                text = "0",
                surface = lobby_surface,
                target = {x = stat_title_x + 15, y = stat_title_y + 5},
                color = {r = 1, g = 1, b = 1},
                alignment = "right",
                scale = 2,
            },
            player_1_arena_victories_title = rendering.draw_text{
                text = "Arena Victories:",
                surface = lobby_surface,
                target = {x = stat_title_x, y = stat_title_y + 6},
                color = {r = 1, g = 1, b = 1},
                alignment = "left",
                scale = 2,
            },
            player_1_arena_victories_total_value = rendering.draw_text{
                text = "0",
                surface = lobby_surface,
                target = {x = stat_title_x + 10, y = stat_title_y + 6},
                color = {r = 1, g = 1, b = 1},
                alignment = "right",
                scale = 2,
            },
            player_1_arena_victories_last_value = rendering.draw_text{
                text = "0",
                surface = lobby_surface,
                target = {x = stat_title_x + 15, y = stat_title_y + 6},
                color = {r = 1, g = 1, b = 1},
                alignment = "right",
                scale = 2,
            },
            player_2_name = rendering.draw_text{
                text = "Player 2",
                surface = lobby_surface,
                target = {x = stat_title_x, y = stat_title_y + 8},
                color = {r = 1, g = 1, b = 1},
                alignment = "left",
                vertical_alignment = "middle",
                scale = 4,
            },
            player_2_overall_score_title = rendering.draw_text{
                text = "Overall Score:",
                surface = lobby_surface,
                target = {x = stat_title_x, y = stat_title_y + 9},
                color = {r = 1, g = 1, b = 1},
                alignment = "left",
                scale = 2,
            },
            player_2_overall_score_total_value = rendering.draw_text{
                text = "0",
                surface = lobby_surface,
                target = {x = stat_title_x + 10, y = stat_title_y + 9},
                color = {r = 1, g = 1, b = 1},
                alignment = "right",
                scale = 2,
            },
            player_2_overall_score_last_value = rendering.draw_text{
                text = "0",
                surface = lobby_surface,
                target = {x = stat_title_x + 15, y = stat_title_y + 9},
                color = {r = 1, g = 1, b = 1},
                alignment = "right",
                scale = 2,
            },
            player_2_total_kills_title = rendering.draw_text{
                text = "Arena Kills:",
                surface = lobby_surface,
                target = {x = stat_title_x, y = stat_title_y + 10},
                color = {r = 1, g = 1, b = 1},
                alignment = "left",
                scale = 2,
            },
            player_2_total_kills_total_value = rendering.draw_text{
                text = "0",
                surface = lobby_surface,
                target = {x = stat_title_x + 10, y = stat_title_y + 10},
                color = {r = 1, g = 1, b = 1},
                alignment = "right",
                scale = 2,
            },
            player_2_total_kills_last_value = rendering.draw_text{
                text = "0",
                surface = lobby_surface,
                target = {x = stat_title_x + 15, y = stat_title_y + 10},
                color = {r = 1, g = 1, b = 1},
                alignment = "right",
                scale = 2,
            },
            player_2_total_deaths_title = rendering.draw_text{
                text = "Arena Deaths:",
                surface = lobby_surface,
                target = {x = stat_title_x, y = stat_title_y + 11},
                color = {r = 1, g = 1, b = 1},
                alignment = "left",
                scale = 2,
            },
            player_2_total_deaths_total_value = rendering.draw_text{
                text = "0",
                surface = lobby_surface,
                target = {x = stat_title_x + 10, y = stat_title_y + 11},
                color = {r = 1, g = 1, b = 1},
                alignment = "right",
                scale = 2,
            },
            player_2_total_deaths_last_value = rendering.draw_text{
                text = "0",
                surface = lobby_surface,
                target = {x = stat_title_x + 15, y = stat_title_y + 11},
                color = {r = 1, g = 1, b = 1},
                alignment = "right",
                scale = 2,
            },
            player_2_top_kills_per_minute_title = rendering.draw_text{
                text = "Top Kills/Minute:",
                surface = lobby_surface,
                target = {x = stat_title_x, y = stat_title_y + 12},
                color = {r = 1, g = 1, b = 1},
                alignment = "left",
                scale = 2,
            },
            player_2_top_kills_per_minute_total_value = rendering.draw_text{
                text = "0",
                surface = lobby_surface,
                target = {x = stat_title_x + 10, y = stat_title_y + 12},
                color = {r = 1, g = 1, b = 1},
                alignment = "right",
                scale = 2,
            },
            player_2_top_kills_per_minute_last_value = rendering.draw_text{
                text = "0",
                surface = lobby_surface,
                target = {x = stat_title_x + 15, y = stat_title_y + 12},
                color = {r = 1, g = 1, b = 1},
                alignment = "right",
                scale = 2,
            },
            player_2_arena_attempts_title = rendering.draw_text{
                text = "Arena Attempts:",
                surface = lobby_surface,
                target = {x = stat_title_x, y = stat_title_y + 13},
                color = {r = 1, g = 1, b = 1},
                alignment = "left",
                scale = 2,
            },
            player_2_arena_attempts_total_value = rendering.draw_text{
                text = "0",
                surface = lobby_surface,
                target = {x = stat_title_x + 10, y = stat_title_y + 13},
                color = {r = 1, g = 1, b = 1},
                alignment = "right",
                scale = 2,
            },
            player_2_arena_attempts_last_value = rendering.draw_text{
                text = "0",
                surface = lobby_surface,
                target = {x = stat_title_x + 15, y = stat_title_y + 13},
                color = {r = 1, g = 1, b = 1},
                alignment = "right",
                scale = 2,
            },
            player_2_arena_victories_title = rendering.draw_text{
                text = "Arena Victories:",
                surface = lobby_surface,
                target = {x = stat_title_x, y = stat_title_y + 14},
                color = {r = 1, g = 1, b = 1},
                alignment = "left",
                scale = 2,
            },
            player_2_arena_victories_total_value = rendering.draw_text{
                text = "0",
                surface = lobby_surface,
                target = {x = stat_title_x + 10, y = stat_title_y + 14},
                color = {r = 1, g = 1, b = 1},
                alignment = "right",
                scale = 2,
            },
            player_2_arena_victories_last_value = rendering.draw_text{
                text = "0",
                surface = lobby_surface,
                target = {x = stat_title_x + 15, y = stat_title_y + 14},
                color = {r = 1, g = 1, b = 1},
                alignment = "right",
                scale = 2,
            },
            player_3_name = rendering.draw_text{
                text = "Player 3",
                surface = lobby_surface,
                target = {x = stat_title_x, y = stat_title_y + 16},
                color = {r = 1, g = 1, b = 1},
                alignment = "left",
                vertical_alignment = "middle",
                scale = 4,
            },
            player_3_overall_score_title = rendering.draw_text{
                text = "Overall Score:",
                surface = lobby_surface,
                target = {x = stat_title_x, y = stat_title_y + 17},
                color = {r = 1, g = 1, b = 1},
                alignment = "left",
                scale = 2,
            },
            player_3_overall_score_total_value = rendering.draw_text{
                text = "0",
                surface = lobby_surface,
                target = {x = stat_title_x + 10, y = stat_title_y + 17},
                color = {r = 1, g = 1, b = 1},
                alignment = "right",
                scale = 2,
            },
            player_3_overall_score_last_value = rendering.draw_text{
                text = "0",
                surface = lobby_surface,
                target = {x = stat_title_x + 15, y = stat_title_y + 17},
                color = {r = 1, g = 1, b = 1},
                alignment = "right",
                scale = 2,
            },
            player_3_total_kills_title = rendering.draw_text{
                text = "Arena Kills:",
                surface = lobby_surface,
                target = {x = stat_title_x, y = stat_title_y + 18},
                color = {r = 1, g = 1, b = 1},
                alignment = "left",
                scale = 2,
            },
            player_3_total_kills_total_value = rendering.draw_text{
                text = "0",
                surface = lobby_surface,
                target = {x = stat_title_x + 10, y = stat_title_y + 18},
                color = {r = 1, g = 1, b = 1},
                alignment = "right",
                scale = 2,
            },
            player_3_total_kills_last_value = rendering.draw_text{
                text = "0",
                surface = lobby_surface,
                target = {x = stat_title_x + 15, y = stat_title_y + 18},
                color = {r = 1, g = 1, b = 1},
                alignment = "right",
                scale = 2,
            },
            player_3_total_deaths_title = rendering.draw_text{
                text = "Arena Deaths:",
                surface = lobby_surface,
                target = {x = stat_title_x, y = stat_title_y + 19},
                color = {r = 1, g = 1, b = 1},
                alignment = "left",
                scale = 2,
            },
            player_3_total_deaths_total_value = rendering.draw_text{
                text = "0",
                surface = lobby_surface,
                target = {x = stat_title_x + 10, y = stat_title_y + 19},
                color = {r = 1, g = 1, b = 1},
                alignment = "right",
                scale = 2,
            },
            player_3_total_deaths_last_value = rendering.draw_text{
                text = "0",
                surface = lobby_surface,
                target = {x = stat_title_x + 15, y = stat_title_y + 19},
                color = {r = 1, g = 1, b = 1},
                alignment = "right",
                scale = 2,
            },
            player_3_top_kills_per_minute_title = rendering.draw_text{
                text = "Top Kills/Minute:",
                surface = lobby_surface,
                target = {x = stat_title_x, y = stat_title_y + 20},
                color = {r = 1, g = 1, b = 1},
                alignment = "left",
                scale = 2,
            },
            player_3_top_kills_per_minute_total_value = rendering.draw_text{
                text = "0",
                surface = lobby_surface,
                target = {x = stat_title_x + 10, y = stat_title_y + 20},
                color = {r = 1, g = 1, b = 1},
                alignment = "right",
                scale = 2,
            },
            player_3_top_kills_per_minute_last_value = rendering.draw_text{
                text = "0",
                surface = lobby_surface,
                target = {x = stat_title_x + 15, y = stat_title_y + 20},
                color = {r = 1, g = 1, b = 1},
                alignment = "right",
                scale = 2,
            },
            player_3_arena_attempts_title = rendering.draw_text{
                text = "Arena Attempts:",
                surface = lobby_surface,
                target = {x = stat_title_x, y = stat_title_y + 21},
                color = {r = 1, g = 1, b = 1},
                alignment = "left",
                scale = 2,
            },
            player_3_arena_attempts_total_value = rendering.draw_text{
                text = "0",
                surface = lobby_surface,
                target = {x = stat_title_x + 10, y = stat_title_y + 21},
                color = {r = 1, g = 1, b = 1},
                alignment = "right",
                scale = 2,
            },
            player_3_arena_attempts_last_value = rendering.draw_text{
                text = "0",
                surface = lobby_surface,
                target = {x = stat_title_x + 15, y = stat_title_y + 21},
                color = {r = 1, g = 1, b = 1},
                alignment = "right",
                scale = 2,
            },
            player_3_arena_victories_title = rendering.draw_text{
                text = "Arena Victories:",
                surface = lobby_surface,
                target = {x = stat_title_x, y = stat_title_y + 22},
                color = {r = 1, g = 1, b = 1},
                alignment = "left",
                scale = 2,
            },
            player_3_arena_victories_total_value = rendering.draw_text{
                text = "0",
                surface = lobby_surface,
                target = {x = stat_title_x + 10, y = stat_title_y + 22},
                color = {r = 1, g = 1, b = 1},
                alignment = "right",
                scale = 2,
            },
            player_3_arena_victories_last_value = rendering.draw_text{
                text = "0",
                surface = lobby_surface,
                target = {x = stat_title_x + 15, y = stat_title_y + 22},
                color = {r = 1, g = 1, b = 1},
                alignment = "right",
                scale = 2,
            },
        }
        update_statistics()
    end
end

---@param event EventData.on_tick
local function on_tick(event)

    if not script.level and script.level.mod_name == "asher_sky" then return end
    global.game_state = global.game_state or "lobby"

    -- lobby mode --
    if global.game_state == "lobby" then

        local lobby_surface = game.surfaces.lobby
        initialize_lobby(lobby_surface)
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
        if game.tick % (60 * 7) == 0 then
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

    -- arena mode --

    for _, player in pairs(game.connected_players) do
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
                update_kills_per_minute_counter(player)
                spawn_level_appropriate_enemy(player)
            end
        end
        local all_players_dead = true
        for _, player in pairs(game.connected_players) do
            if not (player.controller_type == defines.controllers.spectator) then
                all_players_dead = false
            end
            if not (player.controller_type == defines.controllers.character) then
                local nearest_enemy = player.surface.find_nearest_enemy{position = player.position, max_distance = 500}
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
            for _, player in pairs(game.connected_players) do
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
            update_lobby_text(game.surfaces.lobby)
        end
    end
end

script.on_init(on_init)
script.on_event(defines.events.on_tick, on_tick)
script.on_event(defines.events.on_entity_died, on_entity_died)
script.on_event(defines.events.on_player_respawned, on_player_respawned)

---@class active_ability_data
---@field name string
---@field level number
---@field cooldown number
---@field damage number
---@field radius number
---@field default_cooldown number
---@field default_damage number
---@field default_radius number
---@field damage_multiplier number
---@field radius_multiplier number
---@field cooldown_multiplier number
---@field upgrade_order string[]

---@class player_data
---@field level uint
---@field exp uint
---@field abilities table<string, active_ability_data>

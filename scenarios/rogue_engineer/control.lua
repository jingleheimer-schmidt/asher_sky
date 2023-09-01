
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
local aoe_damage_modifier = constants.aoe_damage_modifier

local lobby_util = require("lobby_util")
local update_lobby_tiles = lobby_util.update_lobby_tiles
local reset_lobby_tiles = lobby_util.reset_lobby_tiles
local create_lobby_text = lobby_util.create_lobby_text
local update_lobby_starting_ability_text = lobby_util.update_lobby_starting_ability_text
local initialize_lobby_text_and_tiles = lobby_util.initialize_lobby_text_and_tiles
local reset_player_starting_ability = lobby_util.reset_player_starting_ability
local update_arena_difficulty = lobby_util.update_arena_difficulty
local update_lobby_starting_ability = lobby_util.update_lobby_starting_ability
local randomize_starting_abilities = lobby_util.randomize_starting_abilities

local statistics_util = require("statistics_util")
local update_lobby_statistics_renderings = statistics_util.update_lobby_statistics_renderings
local initialize_statistics_render_ids = statistics_util.initialize_statistics_rendering_ids
local increase_arena_attempts_statistics_data = statistics_util.increase_arena_attempts_statistics_data
local new_attempt_stats_reset = statistics_util.reset_last_attempt_statistics_data
local reset_player_statistics_data = statistics_util.reset_player_statistics_data
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
local filter_valid_entities = general_util.filter_valid_entities

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

local enemy_util = require("enemy_util")
local find_nearest_enemy = enemy_util.find_nearest_enemy
local get_enemies_in_radius = enemy_util.get_enemies_in_radius
local damage_enemies_in_radius = enemy_util.damage_enemies_in_radius
local spawn_new_enemy = enemy_util.spawn_new_enemy
local spawn_level_appropriate_enemy = enemy_util.spawn_level_appropriate_enemy

local ability_util = require("ability_util")
local register_burn_zone = ability_util.register_burn_zone
local create_flamethrower_target = ability_util.create_flamethrower_target
local register_damage_zone = ability_util.register_damage_zone
local register_laser_beam_target = ability_util.register_laser_beam_target
local create_laser_beam = ability_util.create_laser_beam
local register_poison_zone = ability_util.register_poison_zone
local refill_infividual_turret_ammo = ability_util.refill_infividual_turret_ammo
local refill_existing_turrets = ability_util.refill_nearby_turrets
local activate_flamethrower = ability_util.activate_flamethrower
local upgrade_damage = ability_util.upgrade_damage
local upgrade_radius = ability_util.upgrade_radius
local upgrade_cooldown = ability_util.upgrade_cooldown
local ability_upgrade_functions = ability_util.ability_upgrade_functions
local upgrade_named_ability = ability_util.upgrade_named_ability
local upgrade_random_ability = ability_util.upgrade_random_ability
local unlock_named_ability = ability_util.unlock_named_ability
local unlock_random_ability = ability_util.unlock_random_ability

local abilities = require("abilities")
local ability_functions = abilities.ability_functions
local burst = abilities.burst
local punch = abilities.punch
local cure = abilities.cure
local slash = abilities.slash
local rocket_launcher = abilities.rocket_launcher
local pavement = abilities.pavement
local beam_blast = abilities.beam_blast
local discharge_defender = abilities.discharge_defender
local destroyer = abilities.destroyer
local distractor = abilities.distractor
local defender = abilities.defender
local landmine = abilities.landmine
local poison_capsule = abilities.poison_capsule
local slowdown_capsule = abilities.slowdown_capsule
local gun_turret = abilities.gun_turret
local shotgun = abilities.shotgun
local barrier = abilities.barrier
local purifying_light = abilities.purifying_light
local crystal_blossom = abilities.crystal_blossom

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
        -- purifying_light = true,
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
    local lobby_ticks = player_is_in_lobby and (60 * 5) --[[@as uint]]
    local close_finish_ticks = less_than_nine_seconds_remaining and math.ceil(ticks_remaining / 3) --[[@as uint]]
    local arena_ticks = 60 * 8 --[[@as uint]]
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
                ["laser-shooting-speed-"] = true,
            },
        }
        local arena_minutes = arena_ticks_elapsed() / 60 / 60
        for modifier, technologies in pairs(technology_upgrades_by_modifier) do
            local force = game.forces.player
            for i = 1, math.ceil(arena_minutes / modifier) do
                for name, _ in pairs(technologies) do
                    local force_technologies = force.technologies
                    local tech_name = name .. math.min(i, 7)
                    local technology = force_technologies[tech_name]
                    if not technology then break end
                    local prerequisites = technology.prerequisites
                    for _, prerequisite in pairs(prerequisites) do
                        prerequisite.researched = true
                    end
                    technology.researched = true
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

---@param character LuaEntity
local function reset_character_health(character)
    character.health = character.prototype.max_health
end

---@param player LuaPlayer
local function reset_player_health(player)
    local character = valid_player_character(player)
    if character then
        reset_character_health(character)
    end
end

---@param player LuaPlayer
local function reset_player_ability_data(player)
    local starting_ability = global.lobby_options.starting_ability
    local ability_name = global.default_abilities[starting_ability]
    reset_player_starting_ability(ability_name, player)
    -- initialize_player_statistics(player.index)
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

---@param character LuaEntity
---@return boolean
local function character_is_standing_on_arena_entrance(character)
    local position = character.position
    local x = position.x
    local y = position.y
    if (y < 3 and y > -3) and (x < 24 and x > 18) then
        return true
    end
    return false
end

---@param player LuaPlayer
---@return boolean
local function player_is_standing_on_arena_entrance(player)
    local character = valid_player_character(player)
    if character then
        return character_is_standing_on_arena_entrance(character)
    end
    return false
end

local function enter_arena()
    local players = game.connected_players
    local ready_players = {}
    for _, player in pairs(players) do
        local character = valid_player_character(player)
        ready_players[player.index] = character and character_is_standing_on_arena_entrance(character)
    end
    local all_players_ready = false
    for index, bool in pairs(ready_players) do
        if bool then
            all_players_ready = true
        else
            all_players_ready = false
            break
        end
    end
    if not all_players_ready then
        for _, player in pairs(players) do
            local character = valid_player_character(player)
            if character and ready_players[player.index] then
                reset_character_health(character)
            end
        end
    end
    if all_players_ready then
        local actually_ready = false
        for _, player in pairs(players) do
            local character = valid_player_character(player)
            if character then
                local ratio = character.get_health_ratio()
                if ratio < 0.01 then
                    character.health = player.character.prototype.max_health
                    actually_ready = true
                else
                    character.health = character.health - character.prototype.max_health / 180
                end
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
                local player_index = player.index
                new_attempt_stats_reset(player.index)
                increase_arena_attempts_statistics_data(player_index)
                create_arena_gui(player)
                local abilities = global.player_data[player_index].abilities
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
            update_lobby_statistics_renderings()
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
                update_lobby_statistics_renderings()
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
        local position = {x = -20, y = 0}
        position = game.surfaces.lobby.find_non_colliding_position("character", position, 100, 1) or position
        player.teleport(position, "lobby")
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
        initialize_lobby_text_and_tiles()
        for _, player in pairs(connected_players) do
            if player.surface_index ~= lobby_surface.index then
                player.teleport({ x = -20, y = 0 }, lobby_surface)
            end
            if player.character_running_speed_modifier < 0.4 then
                player.character_running_speed_modifier = 0.4
            end
            local lobby_options = global.lobby_options
            local player_index = player.index
            if not global.player_data[player_index] then
                reset_player_ability_data(player)
                reset_player_statistics_data(player_index)
                initialize_statistics_render_ids()
                update_lobby_statistics_renderings()
            end
            local character = valid_player_character(player)
            if character then
                local position = character.position
                local x = position.x
                local y = position.y
                if y < -6 and y > -10 then
                    if x < -4 and x > -10 then
                        if not (lobby_options.difficulty == "easy") then
                            update_arena_difficulty("easy", player)
                        end
                    elseif x < 3 and x > -3 then
                        if not (lobby_options.difficulty == "normal") then
                            update_arena_difficulty("normal", player)
                        end
                    elseif x < 10 and x > 4 then
                        if not (lobby_options.difficulty == "hard") then
                            update_arena_difficulty("hard", player)
                        end
                    else
                        reset_character_health(character)
                    end
                elseif y < 10 and y > 6 then
                    if x < -4 and x > -10 then
                        if not (lobby_options.starting_ability == "ability_1") then
                            update_lobby_starting_ability("ability_1", player)
                        end
                    elseif x < 3 and x > -3 then
                        if not (lobby_options.starting_ability == "ability_2") then
                            update_lobby_starting_ability("ability_2", player)
                        end
                    elseif x < 10 and x > 4 then
                        if not (lobby_options.starting_ability == "ability_3") then
                            update_lobby_starting_ability("ability_3", player)
                        end
                    else
                        reset_character_health(character)
                    end
                elseif y < 3 and y > -3 then
                    if x < 24 and x > 18 then
                        reset_player_ability_data(player)
                        enter_arena()
                    else
                        reset_character_health(character)
                    end
                else
                    reset_character_health(character)
                end
            end
        end
        initialize_statistics_render_ids()
        if game_tick % (60 * 25) == 0 then
            respawn_lobby_practice_enemy()
        end
        if game_tick % (60 * 2) == 0 then
            update_statistics_colors()
        end
    end

    -- lobby and arena --

    for _, player in pairs(connected_players) do
        local player_index = player.index
        global.player_data = global.player_data or {}
        if not global.player_data[player_index] then
            reset_player_ability_data(player)
            reset_player_statistics_data(player_index)
            initialize_statistics_render_ids()
            update_lobby_statistics_renderings()
        end
        local player_data = global.player_data[player_index]
        for ability_name, ability_data in pairs(player_data.abilities) do
            if (((event.tick + (player_index * 25)) % ability_data.cooldown) == 0) then
                local character = valid_player_character(player)
                if character then
                    activate_ability(ability_data, player, character)
                end
            end
        end
        local character = valid_player_character(player)
        if character then
            rendering.draw_circle{
                surface = character.surface,
                target = character.position,
                color = player.chat_color,
                filled = true,
                radius = 0.5,
                time_to_live = 2,
                draw_on_ground = true,
                only_in_alt_mode = true,
            }
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
            local character = valid_player_character(player)
            if character then
                local balance = difficulties[global.lobby_options.difficulty]
                if game_tick % balance == 0 then
                    spawn_level_appropriate_enemy(player)
                end

                local position = character.position
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
            if player.controller_type ~= defines.controllers.spectator then
                all_players_dead = false
            end
            if player.controller_type == defines.controllers.ghost then
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
                local position = {x = -20, y = 0}
                position = game.surfaces.lobby.find_non_colliding_position("character", position, 100, 1) or position
                player.teleport(position, "lobby")
                player.set_controller{type = defines.controllers.god}
                local character = player.create_character() and player.character
                reset_player_ability_data(player)
                destroy_arena_gui(player)
            end
            global.game_state = "lobby"
            global.arena_start_tick = nil
            global.kill_counter_render_ids = nil
            global.remaining_lives = nil
            global.kpm_counter_render_ids = nil
            game.forces.player.reset()
            randomize_starting_abilities()
            update_lobby_starting_ability_text()
            update_lobby_statistics_renderings()
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


-- -- local debug_mode = true

-- local constants = require("constants")
-- local raw_abilities_data = constants.ability_data

-- local basic_player_data = {
--     level = 0,
--     exp = 0,
--     abilities = {
--         punch = {
--             level = 1,
--             cooldown = math.ceil(raw_abilities_data.punch.default_cooldown),
--             damage = raw_abilities_data.punch.default_damage,
--             radius = raw_abilities_data.punch.default_radius,
--             damage_multiplier = raw_abilities_data.punch.damage_multiplier,
--         },
--     },
-- }

-- ---@enum available_abilities
-- local available_abilities = {
--     burst = true,
--     punch = false,
--     cure = true,
-- }

-- ---@param orientation float -- 0 to 1
-- ---@param angle float -- 0 to 1, added to orientation
-- ---@return float -- 0 to 1
-- local function rotate_orientation(orientation, angle)
--     local new_orientation = orientation + angle
--     if new_orientation > 1 then
--         new_orientation = new_orientation - 1
--     elseif new_orientation < 0 then
--         new_orientation = new_orientation + 1
--     end
--     return new_orientation
-- end

-- local function on_init()
--     global.player_data = {}
--     global.damage_zones = {}
--     global.healing_players = {}
-- end

-- ---@param animation_name string
-- ---@param ability_data active_ability_data
-- ---@param player LuaPlayer
-- ---@param position MapPosition?
-- local function draw_animation(animation_name, ability_data, player, position)
--     local raw_ability_data = raw_abilities_data[animation_name]
--     local time_to_live = raw_ability_data.frame_count --[[@as uint]]
--     local character = player.character
--     local target = raw_ability_data.target == "character" and character or position or character.position
--     local speed = 1 --defined in data.lua
--     local scale = ability_data.radius / 2
--     rendering.draw_animation{
--         animation = animation_name,
--         target = target,
--         surface = player.surface,
--         time_to_live = time_to_live,
--         orientation = rotate_orientation(player.character.orientation, 0.25),
--         x_scale = scale,
--         y_scale = scale,
--         animation_offset = -(game.tick * speed) % raw_ability_data.frame_count,
--     }
-- end

-- ---@param name string
-- ---@param radius integer
-- ---@param damage_per_tick number
-- ---@param player LuaPlayer
-- ---@param position MapPosition
-- ---@param surface LuaSurface
-- ---@param final_tick uint
-- local function create_damage_zone(name, radius, damage_per_tick, player, position, surface, final_tick)
--     local damage_zone = {
--         radius = radius,
--         damage_per_tick = damage_per_tick,
--         player = player,
--         position = position,
--         surface = surface,
--         final_tick = final_tick,
--     }
--     local unique_id = name .. "-" .. player.index .. "-" .. game.tick .. "-" .. position.x .. "-" .. position.y
--     global.damage_zones = global.damage_zones or {}
--     global.damage_zones[unique_id] = damage_zone
-- end

-- ---@param radius integer
-- ---@param damage number
-- ---@param position MapPosition
-- ---@param surface LuaSurface
-- ---@param player LuaPlayer
-- local function damage_enemies_in_radius(radius, damage, position, surface, player)
--     local enemies = surface.find_entities_filtered{
--         position = position,
--         radius = radius,
--         force = "enemy",
--         type = "unit",
--     }
--     for _, enemy in pairs(enemies) do
--         enemy.damage(damage, player.force, "impact", player.character)
--     end
--     if debug_mode then
--         rendering.draw_circle{
--             target = position,
--             surface = surface,
--             radius = radius,
--             color = {r = 1, g = 0, b = 0},
--             filled = false,
--             time_to_live = 2,
--         }
--     end
-- end

-- local aoe_damage_modifier = 20

-- ---@param ability_data active_ability_data
-- ---@param player LuaPlayer
-- local function activate_burst_damage(ability_data, player)
--     local position = player.position
--     local surface = player.surface
--     local radius = ability_data.radius
--     local damage_per_tick = ability_data.damage / aoe_damage_modifier
--     local final_tick = game.tick + (raw_abilities_data.burst.frame_count * 1.25)
--     create_damage_zone("burst", radius, damage_per_tick, player, position, surface, final_tick)
-- end

-- ---@param ability_data active_ability_data
-- ---@param player LuaPlayer
-- local function activate_punch_damage(ability_data, player)
--     local radius = ability_data.radius
--     local damage = ability_data.damage
--     local position = player.position
--     local surface = player.surface
--     damage_enemies_in_radius(radius, damage, position, surface, player)
--     local damage_per_tick = damage / aoe_damage_modifier
--     local final_tick = game.tick + (raw_abilities_data.punch.frame_count * 0.75)
--     create_damage_zone("punch", radius, damage_per_tick, player, position, surface, final_tick)
-- end

-- ---@param ability_data active_ability_data
-- ---@param player LuaPlayer
-- local function activate_cure_damage(ability_data, player)
--     global.healing_players = global.healing_players or {}
--     global.healing_players[player.index] = {
--         player = player,
--         damage = ability_data.damage,
--         final_tick = game.tick + (raw_abilities_data.cure.frame_count * 1.25),
--     }
-- end

-- local damage_functions = {
--     burst = activate_burst_damage,
--     punch = activate_punch_damage,
--     cure = activate_cure_damage,
-- }

-- ---@param ability_name string
-- ---@param ability_data active_ability_data
-- ---@param player LuaPlayer
-- local function damage_enemies(ability_name, ability_data, player)
--     local activate_damage = damage_functions and damage_functions[ability_name]
--     if activate_damage then
--         activate_damage(ability_data, player)
--     end
-- end

-- ---@param ability_name string
-- ---@param ability_data active_ability_data
-- ---@param player LuaPlayer
-- local function activate_ability(ability_name, ability_data, player)
--     draw_animation(ability_name, ability_data, player)
--     damage_enemies(ability_name, ability_data, player)
-- end

-- ---@param abilities table<string, active_ability_data>
-- ---@param player LuaPlayer
-- local function upgrade_random_ability(abilities, player)
--     local ability_names = {}
--     for ability_name, ability_data in pairs(abilities) do
--         if ability_data.level < 10 then
--             table.insert(ability_names, ability_name)
--         end
--     end
--     local ability_name = ability_names[math.random(#ability_names)]
--     local ability_data = abilities[ability_name]
--     local upgrade_type = math.random(1, 4)
--     if upgrade_type == 1 then
--         ability_data.cooldown = math.ceil(ability_data.cooldown - ability_data.cooldown * 0.125)
--         game.print("Level up! " .. ability_name .. " cooldown is now " .. ability_data.cooldown .. ".")
--     elseif upgrade_type == 2 then
--         ability_data.radius = ability_data.radius + 1
--         game.print("Level up! " .. ability_name .. " radius is now " .. ability_data.radius .. ".")
--     elseif upgrade_type == 3 then
--         ability_data.damage = ability_data.damage * ability_data.damage_multiplier
--         game.print("Level up! " .. ability_name .. " damage is now " .. ability_data.damage .. ".")
--     elseif upgrade_type == 4 then
--         local character_running_speed_modifier = player.character_running_speed_modifier
--         character_running_speed_modifier = character_running_speed_modifier + 0.125
--         game.print("Level up! " .. "player" .. " speed is now " .. ability_data.level .. ".")
--     end
-- end

-- ---@param player LuaPlayer
-- local function unlock_new_ability(player)
--     local player_data = global.player_data[player.index]
--     local ability_names = {}
--     for name, available in pairs(available_abilities) do
--         if available then
--             table.insert(ability_names, name)
--         end
--     end
--     local ability_name = ability_names[math.random(#ability_names)]
--     if not player_data.abilities[ability_name] then
--         player_data.abilities[ability_name] = {
--             level = 1,
--             cooldown = math.ceil(raw_abilities_data[ability_name].default_cooldown),
--             damage = raw_abilities_data[ability_name].default_damage,
--             radius = raw_abilities_data[ability_name].default_radius,
--             damage_multiplier = raw_abilities_data[ability_name].damage_multiplier,
--         }
--         game.print("New ability unlocked! " .. ability_name .. " is now level 1.")
--         available_abilities[ability_name] = false
--     end
-- end

-- ---@param player LuaPlayer
-- local function update_kill_counter(player)
--     local player_index = player.index
--     global.kill_counters = global.kill_counters or {}
--     global.kill_counters[player_index] = global.kill_counters[player_index] or {
--         render_id = rendering.draw_text{
--             text = "Kills: 0",
--             surface = player.surface,
--             target = player.character,
--             target_offset = { x = 0, y = 2 },
--             color = { r = 1, g = 1, b = 1 },
--             scale = 1.5,
--             alignment = "center",
--         },
--         kill_count = 0,
--     }
--     local kill_counter = global.kill_counters[player_index]
--     kill_counter.kill_count = kill_counter.kill_count + 1
--     rendering.set_text(kill_counter.render_id, "Kills: " .. kill_counter.kill_count)
-- end

-- ---@param event EventData.on_entity_died
-- local function on_entity_died(event)
--     local entity = event.entity
--     local cause = event.cause
--     local player = cause and cause.type == "character" and cause.player
--     if player then
--         local player_data = global.player_data[player.index]
--         player_data.exp = player_data.exp + 1
--         if player_data.exp >= 10 * player_data.level then
--             player_data.exp = 0
--             player_data.level = player_data.level + 1
--             upgrade_random_ability(player_data.abilities, player)
--             local shimmer_data = { radius = 2, level = 1, cooldown = 0, damage = 0 }
--             draw_animation("shimmer", shimmer_data, player)
--             if player_data.level % 5 == 0 then
--                 unlock_new_ability(player)
--             end
--         end
--         update_kill_counter(player)
--     end
-- end

-- ---@param event EventData.on_tick
-- local function on_tick(event)
--     for _, player in pairs(game.connected_players) do
--         if not player.character then return end
--         global.player_data[player.index] = global.player_data[player.index] or basic_player_data
--         local player_data = global.player_data[player.index]
--         for ability_name, ability_data in pairs(player_data.abilities) do
--             if event.tick % ability_data.cooldown == 0 then
--                 activate_ability(ability_name, ability_data, player)
--             end
--         end
--     end
--     for id, damage_zone in pairs(global.damage_zones) do
--         damage_enemies_in_radius(damage_zone.radius, damage_zone.damage_per_tick, damage_zone.position, damage_zone.surface, damage_zone.player)
--         if damage_zone.final_tick <= event.tick then
--             global.damage_zones[id] = nil
--         end
--     end
--     for id, healing_player in pairs(global.healing_players) do
--         local player = healing_player.player
--         if player.character then
--             player.character.damage(healing_player.damage, player.force, "impact", player.character)
--         end
--         if healing_player.final_tick <= event.tick then
--             global.healing_players[id] = nil
--         end
--     end
-- end

-- script.on_init(on_init)
-- script.on_event(defines.events.on_tick, on_tick)
-- script.on_event(defines.events.on_entity_died, on_entity_died)

-- ---@class active_ability_data
-- ---@field level number
-- ---@field cooldown number
-- ---@field damage number
-- ---@field radius number
-- ---@field damage_multiplier number
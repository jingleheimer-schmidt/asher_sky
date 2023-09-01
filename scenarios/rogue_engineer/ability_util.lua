
local constants = require("__asher_sky__/constants")
local raw_abilities_data = constants.ability_data

local general_util = require("general_util")
local filter_valid_entities = general_util.filter_valid_entities

local luarendering_util = require("luarendering_util")
local draw_animation = luarendering_util.draw_animation
local draw_upgrade_text = luarendering_util.draw_upgrade_text
local draw_announcement_text = luarendering_util.draw_announcement_text

local gui_util = require("gooey_util")
local add_arena_gui_ability_info = gui_util.add_arena_gui_ability_info
local update_arena_gui_ability_info = gui_util.update_arena_gui_ability_info

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
local function refill_nearby_turrets(ability_data, character)
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
    local player_abilities = player_data.abilities
    local upgradeable_abilities = {} --[[@type string[]\]]
    for _, ability in pairs(player_abilities) do
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
    local ability_data = player_abilities[ability_name]
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

return {
    register_burn_zone = register_burn_zone,
    create_flamethrower_target = create_flamethrower_target,
    register_damage_zone = register_damage_zone,
    register_laser_beam_target = register_laser_beam_target,
    create_laser_beam = create_laser_beam,
    register_poison_zone = register_poison_zone,
    refill_infividual_turret_ammo = refill_infividual_turret_ammo,
    refill_nearby_turrets = refill_nearby_turrets,
    activate_flamethrower = activate_flamethrower,
    upgrade_damage = upgrade_damage,
    upgrade_radius = upgrade_radius,
    upgrade_cooldown = upgrade_cooldown,
    ability_upgrade_functions = ability_upgrade_functions,
    upgrade_named_ability = upgrade_named_ability,
    upgrade_random_ability = upgrade_random_ability,
    unlock_named_ability = unlock_named_ability,
    unlock_random_ability = unlock_random_ability,
}
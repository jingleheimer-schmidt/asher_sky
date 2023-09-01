
local general_util = require("general_util")
local arena_ticks_elapsed = general_util.arena_ticks_elapsed
local filter_valid_entities = general_util.filter_valid_entities
local get_random_position_on_circumference = general_util.get_random_position_on_circumference

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

return {
    find_nearest_enemy = find_nearest_enemy,
    get_enemies_in_radius = get_enemies_in_radius,
    damage_enemies_in_radius = damage_enemies_in_radius,
    spawn_new_enemy = spawn_new_enemy,
    spawn_level_appropriate_enemy = spawn_level_appropriate_enemy,
}
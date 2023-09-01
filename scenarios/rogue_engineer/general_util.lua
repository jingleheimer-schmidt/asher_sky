
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

---@param degrees number
local function normalize_degrees(degrees)
    return (degrees + 360) % 360
end

---@param center MapPosition
---@param radius number
---@param angle number -- radians
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

---@param table_param table
---@return unknown
local function random_table_value(table_param)
    local keys = {}
    for key, _ in pairs(table_param) do
        table.insert(keys, key)
    end
    return table_param[keys[math.random(#keys)]]
end

---@param table_param table
---@return any
local function random_table_key(table_param)
    local keys = {}
    for key, _ in pairs(table_param) do
        table.insert(keys, key)
    end
    return keys[math.random(#keys)]
end

---@param from MapPosition
---@param to MapPosition
---@return Vector
local function offset_vector(from, to)
    return { x = to.x - from.x, y = to.y - from.y }
end

---@param direction defines.direction
---@return number -- radians
local function direction_to_angle(direction)
    local rotation_offset = -math.pi / 2
    return (direction * 1/8) * 2 * math.pi + rotation_offset
end

---@param direction defines.direction
---@return defines.direction
local function opposite_direction(direction)
    return (direction + 4) % 8
end

---@param ticks number
---@return LocalisedString
local function format_time(ticks)
    local seconds = ticks / 60
    local minutes = math.floor(seconds / 60)
    seconds = seconds - minutes * 60
    return string.format("%d:%02d", minutes, seconds)
end

---@param player LuaPlayer?
---@return LuaEntity?
local function valid_player_character(player)
    if not player then return end
    if not player.valid then return end
    if not player.character then return end
    if not player.character.valid then return end
    return player.character
end

---@param degrees number
---@return number
local function degrees_to_radians(degrees)
    return degrees * (math.pi / 180)
end

---@return uint
local function arena_ticks_remaining()
    local start_tick = global.arena_start_tick or 0
    local game_duration = global.game_duration[global.lobby_options.difficulty]
    local time_remaining = math.max(0, game_duration - (game.tick - start_tick))
    return time_remaining
end

---@return uint
local function arena_ticks_elapsed()
    local start_tick = global.arena_start_tick or 0
    local time_elapsed = game.tick - start_tick
    return time_elapsed
end

---@param position_1 MapPosition
---@param position_2 MapPosition
---@return number
local function distance(position_1, position_2)
    local x = position_1.x - position_2.x
    local y = position_1.y - position_2.y
    return math.sqrt(x * x + y * y)
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

return {
    rotate_orientation = rotate_orientation,
    normalize_degrees = normalize_degrees,
    get_position_on_circumference = get_position_on_circumference,
    get_random_position_on_circumference = get_random_position_on_circumference,
    random_table_value = random_table_value,
    random_table_key = random_table_key,
    offset_vector = offset_vector,
    direction_to_angle = direction_to_angle,
    opposite_direction = opposite_direction,
    format_time = format_time,
    valid_player_character = valid_player_character,
    degrees_to_radians = degrees_to_radians,
    arena_ticks_remaining = arena_ticks_remaining,
    arena_ticks_elapsed = arena_ticks_elapsed,
    distance = distance,
    filter_valid_entities = filter_valid_entities,
}
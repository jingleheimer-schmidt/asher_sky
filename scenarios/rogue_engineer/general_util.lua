
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
---@return unknown
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
    return (direction * 0.125) * 2 * math.pi
end

---@param direction defines.direction
---@return defines.direction
local function opposite_direction(direction)
    return (direction + 4) % 8
end

return {
    rotate_orientation = rotate_orientation,
    get_position_on_circumference = get_position_on_circumference,
    get_random_position_on_circumference = get_random_position_on_circumference,
    random_table_value = random_table_value,
    random_table_key = random_table_key,
    offset_vector = offset_vector,
    direction_to_angle = direction_to_angle,
    opposite_direction = opposite_direction
}
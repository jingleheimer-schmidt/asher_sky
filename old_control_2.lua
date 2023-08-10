-- Create a rotating 3D cube using lines
local function render_rotating_cube(rotation, size, center_position)

    -- local size = 2  -- Size of the cube
    local halfSize = size / 2

    local vertices = {
        {x = -halfSize, y = -halfSize, z = -halfSize},
        {x = halfSize, y = -halfSize, z = -halfSize},
        {x = halfSize, y = halfSize, z = -halfSize},
        {x = -halfSize, y = halfSize, z = -halfSize},
        {x = -halfSize, y = -halfSize, z = halfSize},
        {x = halfSize, y = -halfSize, z = halfSize},
        {x = halfSize, y = halfSize, z = halfSize},
        {x = -halfSize, y = halfSize, z = halfSize}
    }

    local rotatedVertices = {}
    for _, vertex in pairs(vertices) do
        local x1 = vertex.x * math.cos(rotation.y) - vertex.z * math.sin(rotation.y)
        local z1 = vertex.x * math.sin(rotation.y) + vertex.z * math.cos(rotation.y)
        local y1 = vertex.y

        local y2 = y1 * math.cos(rotation.x) - z1 * math.sin(rotation.x)
        local z2 = y1 * math.sin(rotation.x) + z1 * math.cos(rotation.x)
        local x2 = x1

        table.insert(rotatedVertices, {x = x2, y = y2, z = z2})
    end

    local lines = {
        {rotatedVertices[1], rotatedVertices[2]},
        {rotatedVertices[2], rotatedVertices[3]},
        {rotatedVertices[3], rotatedVertices[4]},
        {rotatedVertices[4], rotatedVertices[1]},

        {rotatedVertices[5], rotatedVertices[6]},
        {rotatedVertices[6], rotatedVertices[7]},
        {rotatedVertices[7], rotatedVertices[8]},
        {rotatedVertices[8], rotatedVertices[5]},

        {rotatedVertices[1], rotatedVertices[5]},
        {rotatedVertices[2], rotatedVertices[6]},
        {rotatedVertices[3], rotatedVertices[7]},
        {rotatedVertices[4], rotatedVertices[8]}
    }

    local sortedLines = {}
    local cameraVector = {x = 1, y = 1, z = 1} -- Assuming the camera is looking along the positive z-axis

    for _, line in pairs(lines) do
        local v1 = {x = line[2].x - line[1].x, y = line[2].y - line[1].y, z = line[2].z - line[1].z}
        local v2 = {x = line[1].x - center_position.x, y = line[1].y - center_position.y, z = line[1].z - center_position.z}
        local normal = {
            x = v1.y * v2.z - v1.z * v2.y,
            y = v1.z * v2.x - v1.x * v2.z,
            z = v1.x * v2.y - v1.y * v2.x
        }

        local dotProduct = normal.x * cameraVector.x + normal.y * cameraVector.y + normal.z * cameraVector.z
        local isVisible = dotProduct > 0

        local distance = math.sqrt((line[1].x - center_position.x)^2 + (line[1].y - center_position.y)^2 + (line[1].z - center_position.z)^2)
        table.insert(sortedLines, {line = line, distance = distance, isVisible = isVisible})
    end

    table.sort(sortedLines, function(a, b)
        return a.distance < b.distance
    end)

    local cameraPosition = {x = center_position.x, y = center_position.y, z = -100}  -- Adjust camera position along the z-axis
    local fov = 100  -- Field of view

    for _, entry in pairs(sortedLines) do
        local line = entry.line
        local color = entry.isVisible and {r = 1, g = 1, b = 1, a = 1} or {r = 0.5, g = 0.5, b = 0.5, a = 1}

        local from = {
            x = (line[1].x + center_position.x - cameraPosition.x) * fov / (line[1].z + center_position.z - cameraPosition.z),
            y = (line[1].y + center_position.y - cameraPosition.y) * fov / (line[1].z + center_position.z - cameraPosition.z)
        }
        local to = {
            x = (line[2].x + center_position.x - cameraPosition.x) * fov / (line[2].z + center_position.z - cameraPosition.z),
            y = (line[2].y + center_position.y - cameraPosition.y) * fov / (line[2].z + center_position.z - cameraPosition.z)
        }

        rendering.draw_line({
            color = color,
            width = 10,
            from = {x = from.x, y = from.y},
            to = {x = to.x, y = to.y},
            surface = game.surfaces[1],
            time_to_live = 2,
        })
    end
end

-- Rotate the cube continuously
local function on_tick(event)
    -- local rotationSpeed = 0.01
    -- global.rotation = global.rotation or {x = 4, y = -4}
    -- global.rotation.y = (global.rotation.y + rotationSpeed) % (2 * math.pi)
    -- global.rotation.x = (global.rotation.x + rotationSpeed / 2) % (2 * math.pi)
    -- local rotation = global.rotation
    local player = game.get_player("asher_sky")
    if not player then return end
    local rotation = player.position
    local x = rotation.x
    local y = rotation.y

    -- local distance_from_origin = distance(rotation, {x = 0, y = 0})
    -- local scale = math.max(25, distance_from_origin / 2)
    local scale = 25

    rotation.x = 0 - y / scale
    rotation.y = 0 - x / scale
    local center = {x = player.position.x, y = player.position.y, z = 0}

    -- render_rotating_pyramid(rotation, scale)
    render_rotating_cube(rotation, scale, center)

end

-- Register event handlers
script.on_event(defines.events.on_tick, on_tick)

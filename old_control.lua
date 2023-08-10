-- -- Create a rotating 3D cube using lines
-- local function render_rotating_cube(rotation, size)

--     -- local size = 2  -- Size of the cube
--     local halfSize = size / 2

--     local vertices = {
--         {x = -halfSize, y = -halfSize, z = -halfSize},
--         {x = halfSize, y = -halfSize, z = -halfSize},
--         {x = halfSize, y = halfSize, z = -halfSize},
--         {x = -halfSize, y = halfSize, z = -halfSize},
--         {x = -halfSize, y = -halfSize, z = halfSize},
--         {x = halfSize, y = -halfSize, z = halfSize},
--         {x = halfSize, y = halfSize, z = halfSize},
--         {x = -halfSize, y = halfSize, z = halfSize}
--     }

--     local rotatedVertices = {}
--     for _, vertex in pairs(vertices) do
--         local x1 = vertex.x * math.cos(rotation.y) - vertex.z * math.sin(rotation.y)
--         local z1 = vertex.x * math.sin(rotation.y) + vertex.z * math.cos(rotation.y)
--         local y1 = vertex.y

--         local y2 = y1 * math.cos(rotation.x) - z1 * math.sin(rotation.x)
--         local z2 = y1 * math.sin(rotation.x) + z1 * math.cos(rotation.x)
--         local x2 = x1

--         table.insert(rotatedVertices, {x = x2, y = y2, z = z2})
--     end

--     local lines = {
--         {rotatedVertices[1], rotatedVertices[2]},
--         {rotatedVertices[2], rotatedVertices[3]},
--         {rotatedVertices[3], rotatedVertices[4]},
--         {rotatedVertices[4], rotatedVertices[1]},

--         {rotatedVertices[5], rotatedVertices[6]},
--         {rotatedVertices[6], rotatedVertices[7]},
--         {rotatedVertices[7], rotatedVertices[8]},
--         {rotatedVertices[8], rotatedVertices[5]},

--         {rotatedVertices[1], rotatedVertices[5]},
--         {rotatedVertices[2], rotatedVertices[6]},
--         {rotatedVertices[3], rotatedVertices[7]},
--         {rotatedVertices[4], rotatedVertices[8]}
--     }

--     for _, line in pairs(lines) do
--         rendering.draw_line({
--             color = game.get_player("asher_sky").color,
--             width = 10,
--             from = line[1],
--             to = line[2],
--             surface = game.surfaces[1],
--             time_to_live = 2,
--         })
--     end
-- end

-- -- Create a rotating 3D pyramid using lines
-- local function render_rotating_pyramid(rotation, size)

--     -- local size = 2  -- Size of the pyramid
--     local halfSize = size / 2

--     local vertices = {
--         {x = 0, y = -halfSize, z = 0},  -- Apex of the pyramid
--         {x = -halfSize, y = halfSize, z = -halfSize},
--         {x = halfSize, y = halfSize, z = -halfSize},
--         {x = halfSize, y = halfSize, z = halfSize},
--         {x = -halfSize, y = halfSize, z = halfSize}
--     }

--     local rotatedVertices = {}
--     for _, vertex in pairs(vertices) do
--         local x1 = vertex.x * math.cos(rotation.y) - vertex.z * math.sin(rotation.y)
--         local z1 = vertex.x * math.sin(rotation.y) + vertex.z * math.cos(rotation.y)
--         local y1 = vertex.y

--         local y2 = y1 * math.cos(rotation.x) - z1 * math.sin(rotation.x)
--         local z2 = y1 * math.sin(rotation.x) + z1 * math.cos(rotation.x)
--         local x2 = x1

--         table.insert(rotatedVertices, {x = x2, y = y2, z = z2})
--     end

--     local lines = {
--         -- Base of the pyramid
--         {rotatedVertices[2], rotatedVertices[3]},
--         {rotatedVertices[3], rotatedVertices[4]},
--         {rotatedVertices[4], rotatedVertices[5]},
--         {rotatedVertices[5], rotatedVertices[2]},

--         -- Sides of the pyramid
--         {rotatedVertices[1], rotatedVertices[2]},
--         {rotatedVertices[1], rotatedVertices[3]},
--         {rotatedVertices[1], rotatedVertices[4]},
--         {rotatedVertices[1], rotatedVertices[5]}
--     }

--     for _, line in pairs(lines) do
--         rendering.draw_line({
--             color = {1, 1, 1, 1},
--             width = 10,
--             from = line[1],
--             to = line[2],
--             surface = game.surfaces[1],
--             time_to_live = 2,
--         })
--     end
-- end

-- local function rotate_vertex(vertex, rotation)
--     local x1 = vertex.x * math.cos(rotation.y) - vertex.z * math.sin(rotation.y)
--     local z1 = vertex.x * math.sin(rotation.y) + vertex.z * math.cos(rotation.y)
--     local y1 = vertex.y

--     local y2 = y1 * math.cos(rotation.x) - z1 * math.sin(rotation.x)
--     local z2 = y1 * math.sin(rotation.x) + z1 * math.cos(rotation.x)
--     local x2 = x1

--     return {x = x2, y = y2, z = z2}
-- end

-- -- Create a rotating 3D torus using lines
-- local function render_rotating_torus(rotation, majorRadius, minorRadius, segments, sides, center)
--     local lines = {}

--     -- Calculate the normal vector of the plane parallel to the torus
--     local normal = {x = 0, y = 0, z = 1}
--     normal = rotate_vertex(normal, rotation)

--     for i = 1, segments do
--         local theta = (i - 1) * (2 * math.pi / segments)
--         local nextTheta = i * (2 * math.pi / segments)

--         for j = 1, sides do
--             local phi = (j - 1) * (2 * math.pi / sides)
--             local nextPhi = j * (2 * math.pi / sides)

--             local x = (majorRadius + minorRadius * math.cos(phi)) * math.cos(theta)
--             local y = (majorRadius + minorRadius * math.cos(phi)) * math.sin(theta)
--             local z = minorRadius * math.sin(phi)

--             local nextX = (majorRadius + minorRadius * math.cos(phi)) * math.cos(nextTheta)
--             local nextY = (majorRadius + minorRadius * math.cos(phi)) * math.sin(nextTheta)
--             local nextZ = minorRadius * math.sin(phi)

--             local from = {x = x, y = y, z = z}
--             local to = {x = nextX, y = nextY, z = nextZ}

--             -- Apply rotation to the vertices
--             from = rotate_vertex(from, rotation)
--             to = rotate_vertex(to, rotation)

--             from.x = from.x + center.x
--             from.y = from.y + center.y
--             from.z = from.z + center.z
--             to.x = to.x + center.x
--             to.y = to.y + center.y
--             to.z = to.z + center.z

--             -- Calculate the dot product between the line direction and the normal vector
--             local dot_product_from = from.x * normal.x + from.y * normal.y + from.z * normal.z
--             local dot_product_to = to.x * normal.x + to.y * normal.y + to.z * normal.z

--             -- Determine whether the line is on the back or front side of the torus
--             local is_back_side = dot_product_from < 0 and dot_product_to < 0

--             -- Calculate depth values for the two points of the line
--             local depth_from = from.x * normal.x + from.y * normal.y + from.z * normal.z
--             local depth_to = to.x * normal.x + to.y * normal.y + to.z * normal.z

--             if not is_back_side or depth_from > 0 or depth_to > 0 then
--                 table.insert(lines, {from, to})
--             end
--         end
--     end

--     for _, line in pairs(lines) do
--         rendering.draw_line({
--             color = {r = 1, g = 1, b = 1},
--             width = 2,
--             from = line[1],
--             to = line[2],
--             surface = game.surfaces[1],
--             time_to_live = 2,
--         })
--     end
-- end



-- -- Create a rotating 3D sphere using lines
-- local function render_rotating_sphere(rotation, radius, rings, segments)
--     local lines = {}

--     for i = 1, rings + 1 do
--         local theta1 = (i - 1) * math.pi / rings
--         local theta2 = i * math.pi / rings

--         for j = 1, segments + 1 do
--             local phi = (j - 1) * 2 * math.pi / segments
--             local nextPhi = j * 2 * math.pi / segments

--             local x1 = radius * math.sin(theta1) * math.cos(phi)
--             local y1 = radius * math.sin(theta1) * math.sin(phi)
--             local z1 = radius * math.cos(theta1)

--             local x2 = radius * math.sin(theta2) * math.cos(nextPhi)
--             local y2 = radius * math.sin(theta2) * math.sin(nextPhi)
--             local z2 = radius * math.cos(theta2)

--             local from = {x = x1, y = y1, z = z1}
--             local to = {x = x2, y = y2, z = z2}

--             -- Apply rotation to the vertices
--             from = {
--                 x = from.x * math.cos(rotation.y) - from.z * math.sin(rotation.y),
--                 z = from.x * math.sin(rotation.y) + from.z * math.cos(rotation.y),
--                 y = from.y * math.cos(rotation.x) - from.z * math.sin(rotation.x),
--             }
--             to = {
--                 x = to.x * math.cos(rotation.y) - to.z * math.sin(rotation.y),
--                 z = to.x * math.sin(rotation.y) + to.z * math.cos(rotation.y),
--                 y = to.y * math.cos(rotation.x) - to.z * math.sin(rotation.x),
--             }

--             table.insert(lines, {from, to})
--         end
--     end

--     for _, line in pairs(lines) do
--         rendering.draw_line({
--             color = {r = 1, g = 1, b = 1},
--             width = 2,
--             from = line[1],
--             to = line[2],
--             surface = game.surfaces[1],
--             time_to_live = 2,
--         })
--     end
-- end

-- -- Create a rotating 3D sphere using lines with a center location
-- local function render_rotating_sphere_with_center(rotation, radius, rings, segments, center)
--     local lines = {}

--     for i = 1, rings + 1 do
--         local theta1 = (i - 1) * math.pi / rings
--         local theta2 = i * math.pi / rings

--         for j = 1, segments + 1 do
--             local phi = (j - 1) * 2 * math.pi / segments
--             local nextPhi = j * 2 * math.pi / segments

--             local x1 = radius * math.sin(theta1) * math.cos(phi)
--             local y1 = radius * math.sin(theta1) * math.sin(phi)
--             local z1 = radius * math.cos(theta1)

--             local x2 = radius * math.sin(theta2) * math.cos(phi)
--             local y2 = radius * math.sin(theta2) * math.sin(phi)
--             local z2 = radius * math.cos(theta2)

--             local from = {x = x1, y = y1, z = z1}
--             local to = {x = x2, y = y2, z = z2}

--             -- Apply translation to center the animation
--             from.x = from.x + center.x
--             from.y = from.y + center.y
--             from.z = from.z + center.z

--             to.x = to.x + center.x
--             to.y = to.y + center.y
--             to.z = to.z + center.z

--             -- Apply rotation to the vertices
--             from = {
--                 x = from.x * math.cos(rotation.y) - from.z * math.sin(rotation.y),
--                 z = from.x * math.sin(rotation.y) + from.z * math.cos(rotation.y),
--                 y = from.y * math.cos(rotation.x) - from.z * math.sin(rotation.x),
--             }
--             to = {
--                 x = to.x * math.cos(rotation.y) - to.z * math.sin(rotation.y),
--                 z = to.x * math.sin(rotation.y) + to.z * math.cos(rotation.y),
--                 y = to.y * math.cos(rotation.x) - to.z * math.sin(rotation.x),
--             }

--             table.insert(lines, {from, to})
--         end
--     end

--     for _, line in pairs(lines) do
--         rendering.draw_line({
--             color = {r = 1, g = 1, b = 1},
--             width = 2,
--             from = line[1],
--             to = line[2],
--             surface = game.surfaces[1],
--             time_to_live = 2,
--         })
--     end
-- end

-- local function distance(position_1, position_2)
--     return math.sqrt((position_1.x - position_2.x) ^ 2 + (position_1.y - position_2.y) ^ 2)
-- end

-- -- Rotate the cube continuously
-- local function on_tick(event)
--     -- local rotationSpeed = 0.01
--     -- global.rotation = global.rotation or {x = 4, y = -4}
--     -- global.rotation.y = (global.rotation.y + rotationSpeed) % (2 * math.pi)
--     -- global.rotation.x = (global.rotation.x + rotationSpeed / 2) % (2 * math.pi)
--     -- local rotation = global.rotation
--     local player = game.get_player("asher_sky")
--     if not player then return end
--     local rotation = player.position
--     local x = rotation.x
--     local y = rotation.y

--     local distance_from_origin = distance(rotation, {x = 0, y = 0})
--     local scale = math.max(25, distance_from_origin / 2)

--     rotation.x = 0 - y / 10
--     rotation.y = 0 - x / 10

--     -- -- render_rotating_pyramid(rotation, scale)
--     -- -- render_rotating_cube(rotation, scale)
--     local majorRadius = 6 * 1.5
--     local minorRadius = 2
--     local segments = 36
--     local sides = 18
--     local center = {x = player.position.x, y = player.position.y, z = 0}

--     render_rotating_torus(rotation, majorRadius, minorRadius, segments, sides, center)

--     -- Rotate the sphere continuously based on player location
--     local radius = 5
--     local rings = 24
--     local segments = 36
--     local center = {x = player.position.x, y = player.position.y, z = 0}

--     -- render_rotating_sphere(rotation, radius, rings, segments)
--     -- render_rotating_sphere_with_center(rotation, radius, rings, segments, center)
-- end

-- -- Register event handlers
-- script.on_event(defines.events.on_tick, on_tick)


local constants = require("__asher_sky__/constants")
local raw_abilities_data = constants.ability_data

local statistics_util = require("statistics_util")
local calculate_kills_per_minute = statistics_util.calculate_kills_per_minute
local update_kpm_statistics = statistics_util.update_kpm_statistics

---@param name string
---@param target LuaEntity|MapPosition
---@param surface LuaSurface
---@param orientation float?
---@param scale number?
---@param frame_count uint?
---@param render_layer RenderLayer?
local function draw_animation(name, target, surface, orientation, scale, frame_count, render_layer)
    scale = scale and scale / 2 or 1/2
    frame_count = frame_count or raw_abilities_data[name] and raw_abilities_data[name].frame_count or nil
    local offset = 0
    if frame_count then
        offset = -(game.tick) % frame_count
    end
    rendering.draw_animation{
        animation = name,
        target = target,
        surface = surface,
        time_to_live = frame_count,
        orientation = orientation,
        x_scale = scale,
        y_scale = scale,
        animation_offset = offset,
        render_layer = render_layer,
    }
end

---@param text LocalisedString
---@param surface LuaSurface
---@param target MapPosition|LuaEntity
---@param color Color
---@param scale double?
---@param time_to_live uint?
---@param target_offset Vector?
---@param use_rich_text boolean?
---@param draw_on_ground boolean?
---@return uint64
local function draw_text(text, surface, target, color, time_to_live, scale, target_offset, use_rich_text, draw_on_ground)
    local render_id = rendering.draw_text{
        text = text,
        surface = surface,
        target = target,
        color = color,
        time_to_live = time_to_live,
        scale = scale,
        alignment = "center",
        target_offset = target_offset,
        use_rich_text = use_rich_text,
        draw_on_ground = draw_on_ground,
    }
    return render_id
end

---@param text string|LocalisedString
---@param player LuaPlayer
---@param offset Vector?
local function draw_upgrade_text(text, player, offset)
    local position = player.position
    local surface = player.surface
    local color = player.chat_color
    local time_to_live = 60 * 8
    local scale = 3.5
    if offset then
        position.x = position.x + offset.x
        position.y = position.y + offset.y
    end
    draw_text(text, surface, position, color, time_to_live, scale, offset)
end

---@param text string|LocalisedString
---@param player LuaPlayer
local function draw_announcement_text(text, player)
    local position = player.position
    local surface = player.surface
    local color = player.chat_color
    local time_to_live = 60 * 15
    local scale = 5
    draw_text(text, surface, position, color, time_to_live, scale)
end

---@param character LuaEntity
---@return uint64
local function create_kill_counter_rendering(character)
    local text = {"", {"message_locale.kills"}, ": ", "0"}
    local surface = character.surface
    local color = { r = 1, g = 1, b = 1 }
    local time_to_live = nil
    local scale = 1.5
    local offset = { x = 0, y = 1 }
    local render_id = draw_text(text, surface, character, color, time_to_live, scale, offset)
    return render_id
end

---@param character LuaEntity
---@return uint64
local function create_kpm_counter_rendering(character)
    local text = {"", {"message_locale.kills_per_minute"}, ": [color=", "white", "]", "0", "[/color]"}
    local surface = character.surface
    local color = { r = 1, g = 1, b = 1 }
    local time_to_live = nil
    local scale = 1.5
    local offset = { x = 0, y = 2 }
    local use_rich_text = true
    local render_id = draw_text(text, surface, character, color, time_to_live, scale, offset, use_rich_text)
    return render_id
end

---@param character LuaEntity
---@return uint64
local function create_arena_clock_rendering(character)
    local text = {"", {"message_locale.time_remaining"}, ": ", "0"}
    local surface = character.surface
    local color = { r = 1, g = 1, b = 1 }
    local time_to_live = nil
    local scale = 1.5
    local offset = { x = 0, y = 3 }
    local use_rich_text = true
    local render_id = draw_text(text, surface, character, color, time_to_live, scale, offset, use_rich_text)
    return render_id
end

---@param character LuaEntity
---@return uint64
local function create_lives_remaining_rendering(character)
    local text = {"", {"message_locale.lives_remaining"}, ": ", "0"}
    local surface = character.surface
    local color = { r = 1, g = 1, b = 1 }
    local time_to_live = nil
    local scale = 1.5
    local offset = { x = 0, y = 4 }
    local use_rich_text = true
    local render_id = draw_text(text, surface, character, color, time_to_live, scale, offset, use_rich_text)
    return render_id
end

---@param player_index uint
---@param character LuaEntity
local function update_kill_counter_rendering(player_index, character)
    global.kill_counter_render_ids = global.kill_counter_render_ids or {} --[[@type table<uint, uint64>]]
    global.kill_counter_render_ids[player_index] = global.kill_counter_render_ids[player_index] or create_kill_counter_rendering(character)
    local render_id = global.kill_counter_render_ids[player_index]
    local statistics = global.statistics[player_index]
    local kill_count = statistics and statistics.last_attempt.kills or 0
    if not rendering.is_valid(render_id) then
        render_id = create_kill_counter_rendering(character)
    end
    global.kill_counter_render_ids[player_index] = render_id
    local text = {"", {"message_locale.kills"}, ": ", kill_count}
    rendering.set_text(render_id, text)
end

---@param player_index uint
---@param character LuaEntity
local function update_kpm_counter_rendering(player_index, character)
    global.kpm_counter_render_ids = global.kpm_counter_render_ids or {} --[[@type table<uint, uint64>]]
    global.kpm_counter_render_ids[player_index] = global.kpm_counter_render_ids[player_index] or create_kpm_counter_rendering(character)
    local render_id = global.kpm_counter_render_ids[player_index]
    if not rendering.is_valid(render_id) then
        render_id = create_kpm_counter_rendering(character)
    end
    global.kpm_counter_render_ids[player_index] = render_id
    local kills_per_minute = calculate_kills_per_minute(player_index)
    local last_text = rendering.get_text(render_id) --[[@as LocalisedString]]
    local last_color = last_text and last_text[4] or "white"
    local last_kpm = last_text and tonumber(last_text[6]) or 0
    local color = kills_per_minute > last_kpm and "green" or kills_per_minute < last_kpm and "red" or "white"
    local text = {"", {"message_locale.kills_per_minute"}, ": [color=", color, "]", kills_per_minute, "[/color]"}
    rendering.set_text(render_id, text)
    update_kpm_statistics(player_index, kills_per_minute)
end

---@param player_index uint
---@param character LuaEntity
local function update_arena_clock_rendering(player_index, character)
    local start_tick = global.arena_start_tick
    if not start_tick then return end
    local game_duration = global.game_duration[global.lobby_options.difficulty]
    if not game_duration then return end
    global.time_remaining_render_ids = global.time_remaining_render_ids or {}
    global.time_remaining_render_ids[player_index] = global.time_remaining_render_ids[player_index] or create_arena_clock_rendering(character)
    local render_id = global.time_remaining_render_ids[player_index]
    if not rendering.is_valid(render_id) then
        render_id = create_arena_clock_rendering(character)
    end
    global.time_remaining_render_ids[player_index] = render_id
    local time_remaining = game_duration - (game.tick - start_tick)
    local text = {"", {"message_locale.time_remaining"}, ": ", format_time(time_remaining)}
    rendering.set_text(render_id, text)
end

---@param player_index uint
---@param character LuaEntity
local function update_lives_remaining_rendering(player_index, character)
    global.lives_remaining_render_ids = global.lives_remaining_render_ids or {}
    global.lives_remaining_render_ids[player_index] = global.lives_remaining_render_ids[player_index] or create_lives_remaining_rendering(character)
    local render_id = global.lives_remaining_render_ids[player_index]
    if not rendering.is_valid(render_id) then
        render_id = create_lives_remaining_rendering(character)
    end
    global.lives_remaining_render_ids[player_index] = render_id
    local lives_remaining = global.remaining_lives and global.remaining_lives[player_index] or 0
    local text = {"", {"message_locale.lives_remaining"}, ": ", lives_remaining}
    rendering.set_text(render_id, text)
end

return {
    draw_animation = draw_animation,
    draw_text = draw_text,
    draw_upgrade_text = draw_upgrade_text,
    draw_announcement_text = draw_announcement_text,
    update_kill_counter_rendering = update_kill_counter_rendering,
    update_kpm_counter_rendering = update_kpm_counter_rendering,
    update_arena_clock_rendering = update_arena_clock_rendering,
    update_lives_remaining_rendering = update_lives_remaining_rendering
}
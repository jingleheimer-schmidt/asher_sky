
local font = "arena-gui-default-bold"

local statistics_util = require("statistics_util")
local calculate_kills_per_minute = statistics_util.calculate_kills_per_minute

local general_util = require("general_util")
local format_time = general_util.format_time

---@param player LuaPlayer
local function create_arena_gui(player)
    local screen = player.gui.screen
    if screen.arena_gui then
        screen.arena_gui.destroy()
    end
    screen.add{
        type = "flow",
        name = "arena_gui",
        direction = "vertical",
    }
    local arena_gui = screen.arena_gui
    if not arena_gui then return end
    arena_gui.style.top_padding = 25
    arena_gui.style.left_padding = 25
    arena_gui.add {
        type = "label",
        name = "total_kills",
        caption = { "", { "message_locale.kills" }, ": ", 0 },
    }
    arena_gui.total_kills.style.font = font
    arena_gui.add {
        type = "label",
        name = "kills_per_minute",
        caption = { "", { "message_locale.kills_per_minute" }, ": [color=", "white", "]", 0, "[/color]" },
    }
    arena_gui.kills_per_minute.style.font = font
    arena_gui.add {
        type = "label",
        name = "time_remaining",
        caption = { "", { "message_locale.time_remaining" }, ": ", 0 },
    }
    arena_gui.time_remaining.style.font = font
    arena_gui.add {
        type = "label",
        name = "lives_remaining",
        caption = { "", { "message_locale.lives_remaining" }, ": ", 0 },
    }
    arena_gui.lives_remaining.style.font = font
    arena_gui.add {
        type = "label",
        name = "active_abilities",
        caption = { "", { "message_locale.active_abilities" } },
    }
    arena_gui.active_abilities.style.font = font
    local player_data = global.player_data[player.index]
    if not player_data then return end
    local abilities = player_data.abilities
    for _, ability_data in pairs(abilities) do
        local name = ability_data.name
        local level = ability_data.level
        local max_level = #ability_data.upgrade_order + 1
        arena_gui.add {
            type = "table",
            name = "active_abilities_table",
            column_count = 2,
        }
        arena_gui.active_abilities_table.add {
            type = "label",
            name = name .. "_title",
            caption = { "", { "ability_name." .. name }, ": "},
        }
        arena_gui.active_abilities_table.add {
            type = "label",
            name = name .. "_level",
            caption = { "", { "upgrade_locale.lvl" }, " ", level, " / ", max_level },
        }
        arena_gui.active_abilities_table[name .. "_title"].style.font = font
        arena_gui.active_abilities_table[name .. "_level"].style.font = font
    end
end

---@param player LuaPlayer
---@param arena_gui LuaGuiElement?
---@param player_stats player_statistics?
local function update_arena_gui_kills(player, arena_gui, player_stats)
    if not arena_gui then
        arena_gui = player.gui.screen.arena_gui
        if not arena_gui then return end
    end
    if not player_stats then
        player_stats = global.statistics and global.statistics[player.index]
        if not player_stats then return end
    end
    local last_stats = player_stats.last_attempt
    local kills = last_stats and last_stats.kills or 0
    arena_gui.total_kills.caption = { "", { "message_locale.kills" }, ": ", kills }
end

---@param player LuaPlayer
---@param arena_gui LuaGuiElement?
---@param player_stats player_statistics?
local function update_arena_gui_kills_per_minute(player, arena_gui, player_stats)
    if not arena_gui then
        arena_gui = player.gui.screen.arena_gui
        if not arena_gui then return end
    end
    if not player_stats then
        player_stats = global.statistics and global.statistics[player.index]
        if not player_stats then return end
    end
    local kills_per_minute = calculate_kills_per_minute(player.index)
    local last_text = arena_gui.kills_per_minute.caption
    local last_color = last_text and last_text[4] or "white"
    local last_kills_per_minute = tonumber(last_text and last_text[6] or 0)
    local color = "white"
    if kills_per_minute > last_kills_per_minute then
        color = "green"
    elseif kills_per_minute < last_kills_per_minute then
        color = "red"
    end
    arena_gui.kills_per_minute.caption = { "", { "message_locale.kills_per_minute" }, ": [color=", color, "]", kills_per_minute, "[/color]" }
end

---@param player LuaPlayer
---@param arena_gui LuaGuiElement?
---@param player_stats player_statistics?
local function update_arena_gui_time_remaining(player, arena_gui, player_stats)
    if not arena_gui then
        arena_gui = player.gui.screen.arena_gui
        if not arena_gui then return end
    end
    if not player_stats then
        player_stats = global.statistics and global.statistics[player.index]
        if not player_stats then return end
    end
    local arena_start_tick = global.arena_start_tick
    local game_duration = global.game_duration[global.lobby_options.difficulty]
    local time_remaining = math.max(0, game_duration - (game.tick - arena_start_tick))
    arena_gui.time_remaining.caption = { "", { "message_locale.time_remaining" }, ": ", format_time(time_remaining) }
end

---@param player LuaPlayer
---@param arena_gui LuaGuiElement?
---@param player_stats player_statistics?
local function update_arena_gui_lives_remaining(player, arena_gui, player_stats)
    if not arena_gui then
        arena_gui = player.gui.screen.arena_gui
        if not arena_gui then return end
    end
    if not player_stats then
        player_stats = global.statistics and global.statistics[player.index]
        if not player_stats then return end
    end
    local lives_remaining = global.remaining_lives and global.remaining_lives[player.index] or 0
    arena_gui.lives_remaining.caption = { "", { "message_locale.lives_remaining" }, ": ", lives_remaining }
end

local function update_arena_gui(player)
    local arena_gui = player.gui.screen.arena_gui
    local player_stats = global.statistics and global.statistics[player.index]
    update_arena_gui_kills(player, arena_gui, player_stats)
    update_arena_gui_kills_per_minute(player, arena_gui, player_stats)
    update_arena_gui_time_remaining(player, arena_gui, player_stats)
    update_arena_gui_lives_remaining(player, arena_gui, player_stats)
end

local function destroy_arena_gui(player)
    local screen = player.gui.screen
    if screen.arena_gui then
        screen.arena_gui.destroy()
    end
end

---@param player LuaPlayer
---@param ability_data active_ability_data
local function add_arena_gui_ability_info(player, ability_data)
    local arena_gui = player.gui.screen.arena_gui
    if not arena_gui then return end
    local name = ability_data.name
    local level = ability_data.level
    local max_level = #ability_data.upgrade_order + 1
    arena_gui.active_abilities_table.add {
        type = "label",
        name = name .. "_title",
        caption = { "", { "ability_name." .. name }, ": "},
    }
    arena_gui.active_abilities_table.add {
        type = "label",
        name = name .. "_level",
        caption = { "", { "upgrade_locale.lvl" }, " ", level, " / ", max_level },
    }
    arena_gui.active_abilities_table[name .. "_title"].style.font = font
    arena_gui.active_abilities_table[name .. "_level"].style.font = font
end

---@param player LuaPlayer
---@param ability_data active_ability_data
local function update_arena_gui_ability_info(player, ability_data)
    local arena_gui = player.gui.screen.arena_gui
    if not arena_gui then return end
    local ability_info = arena_gui.active_abilities_table[ability_data.name .. "_level"]
    if not ability_info then return end
    local name = ability_data.name
    local level = ability_data.level
    local max_level = #ability_data.upgrade_order + 1
    ability_info.caption = { "", { "upgrade_locale.lvl" }, " ", level, " / ", max_level }
end

return {
    create_arena_gui = create_arena_gui,
    update_arena_gui_kills = update_arena_gui_kills,
    update_arena_gui_kills_per_minute = update_arena_gui_kills_per_minute,
    update_arena_gui_time_remaining = update_arena_gui_time_remaining,
    update_arena_gui_lives_remaining = update_arena_gui_lives_remaining,
    update_arena_gui = update_arena_gui,
    destroy_arena_gui = destroy_arena_gui,
    add_arena_gui_ability_info = add_arena_gui_ability_info,
    update_arena_gui_ability_info = update_arena_gui_ability_info,
}
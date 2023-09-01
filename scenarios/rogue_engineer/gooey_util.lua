
local font = "arena-gui-default-bold"

local statistics_util = require("statistics_util")
local calculate_kills_per_minute = statistics_util.calculate_kills_per_minute

local general_util = require("general_util")
local format_time = general_util.format_time
local arena_ticks_remaining = general_util.arena_ticks_remaining
local arena_ticks_elapsed = general_util.arena_ticks_elapsed

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
        name = "arena_stats_title",
        caption = { "", { "message_locale.arena_statistics" } },
    }
    arena_gui.arena_stats_title.style.font = font
    arena_gui.add {
        type = "table",
        name = "player_stats_table",
        column_count = 2,
    }
    local player_stats_table = arena_gui.player_stats_table
    if not player_stats_table then return end
    player_stats_table.add {
        type = "label",
        name = "total_kills_title",
        caption = { "", { "message_locale.kills" }, ": " },
    }
    player_stats_table.total_kills_title.style.font = font
    player_stats_table.add {
        type = "label",
        name = "total_kills_value",
        caption = { "", 0 },
    }
    player_stats_table.total_kills_value.style.font = font
    player_stats_table.add {
        type = "label",
        name = "kills_per_minute_title",
        caption = { "", { "message_locale.kills_per_minute" }, ": " },
    }
    player_stats_table.kills_per_minute_title.style.font = font
    player_stats_table.add {
        type = "label",
        name = "kills_per_minute_value",
        caption = {"", "[color=", "white", "]", 0, "[/color]"}
    }
    player_stats_table.kills_per_minute_value.style.font = font
    player_stats_table.add {
        type = "label",
        name = "time_remaining_title",
        caption = { "", { "message_locale.time_remaining" }, ": "},
    }
    player_stats_table.time_remaining_title.style.font = font
    player_stats_table.add {
        type = "label",
        name = "time_remaining_value",
        caption = { "", 0 },
    }
    player_stats_table.time_remaining_value.style.font = font
    player_stats_table.add {
        type = "label",
        name = "lives_remaining_title",
        caption = { "", { "message_locale.lives_remaining" }, ": "},
    }
    player_stats_table.lives_remaining_title.style.font = font
    player_stats_table.add {
        type = "label",
        name = "lives_remaining_value",
        caption = { "", 0 },
    }
    player_stats_table.lives_remaining_value.style.font = font
    arena_gui.add {
        type = "label",
        name = "spacer",
        caption = { "", " " },
    }
    arena_gui.spacer.style.font = font
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
    arena_gui.player_stats_table["total_kills_value"].caption = { "", kills }
end

---@param player LuaPlayer
---@param arena_gui LuaGuiElement?
---@param player_stats player_statistics?
local function update_arena_gui_kills_per_minute(player, arena_gui, player_stats)
    if not arena_gui then
        arena_gui = player.gui.screen.arena_gui.player_stats_table
        if not arena_gui then return end
    end
    if not player_stats then
        player_stats = global.statistics and global.statistics[player.index]
        if not player_stats then return end
    end
    local kills_per_minute = calculate_kills_per_minute(player.index)
    local last_text = arena_gui.player_stats_table["kills_per_minute_value"].caption
    local last_color = last_text and last_text[3] or "white"
    local last_kills_per_minute = tonumber(last_text and last_text[5] or 0)
    local color = "white"
    if kills_per_minute > last_kills_per_minute then
        color = "green"
    elseif kills_per_minute < last_kills_per_minute then
        color = "red"
    end
    arena_gui.player_stats_table["kills_per_minute_value"].caption = { "", "[color=", color, "]", kills_per_minute, "[/color]" }
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
    local time_remaining = arena_ticks_remaining()
    arena_gui.player_stats_table["time_remaining_value"].caption = { "", format_time(time_remaining) }
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
    arena_gui.player_stats_table["lives_remaining_value"].caption = { "", lives_remaining }
end

local function update_arena_gui(player)
    local arena_gui = player.gui.screen.arena_gui
    local player_stats = global.statistics and global.statistics[player.index]
    if not arena_gui or not player_stats then return end
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
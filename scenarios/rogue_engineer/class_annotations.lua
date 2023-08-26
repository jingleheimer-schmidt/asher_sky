
---@class active_ability_data
---@field name string
---@field level number
---@field cooldown number
---@field damage number
---@field radius number
---@field default_cooldown number
---@field default_damage number
---@field default_radius number
---@field damage_multiplier number
---@field radius_multiplier number
---@field cooldown_multiplier number
---@field upgrade_order string[]

---@class player_data
---@field level uint
---@field exp uint
---@field abilities table<string, active_ability_data>

---@class player_statistics_data
---@field kills uint
---@field deaths uint
---@field damage_dealt uint
---@field damage_taken uint
---@field damage_healed uint
---@field attempts uint
---@field victories uint
---@field top_kills_per_minute uint

---@class player_statistics
---@field total player_statistics_data
---@field last_attempt player_statistics_data

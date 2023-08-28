
local function update_statistics()
    local players = game.players
    local statistics = global.statistics --[[@type table<uint, player_statistics>]]
    local render_ids = global.statistics_render_ids
    local player_total_scores = {}
    local player_last_scores = {}
    for _, player in pairs(players) do
        local player_index = player.index
        local player_stats = statistics[player_index]
        local total_score = (player_stats.total.kills / (player_stats.total.deaths + 1)) * (player_stats.total.victories + 1 / (player_stats.total.attempts + 1))
        player_total_scores[player_index] = total_score
        local last_score = (player_stats.last_attempt.kills / (player_stats.last_attempt.deaths + 1)) * (player_stats.last_attempt.victories + 1 / (player_stats.last_attempt.attempts + 1))
        player_last_scores[player_index] = last_score
    end
    local sorted_total_scores = {}
    local sorted_last_scores = {}
    for player_index, score in pairs(player_total_scores) do
        table.insert(sorted_total_scores, {player_index = player_index, score = score})
    end
    for player_index, score in pairs(player_last_scores) do
        table.insert(sorted_last_scores, {player_index = player_index, score = score})
    end
    table.sort(sorted_total_scores, function(a, b) return a.score > b.score end)
    table.sort(sorted_last_scores, function(a, b) return a.score > b.score end)
    local player_1 = sorted_total_scores[1] and sorted_total_scores[1].player_index
    local player_2 = sorted_total_scores[2] and sorted_total_scores[2].player_index
    local player_3 = sorted_total_scores[3] and sorted_total_scores[3].player_index

    local player_1_stats = statistics[player_1]
    local player_2_stats = statistics[player_2]
    local player_3_stats = statistics[player_3]

    if player_1 then
        for name, render_id in pairs(render_ids) do
            if name:find("player_1") and name:find("title") then
                if rendering.is_valid(render_id) then
                    rendering.set_color(render_id, players[player_1].chat_color)
                end
            end
        end
        rendering.set_text(render_ids.player_1_name, players[player_1].name)
        rendering.set_color(render_ids.player_1_name, players[player_1].chat_color)
        rendering.set_text(render_ids.player_1_overall_score_total_value, sorted_total_scores[player_1] and math.ceil(sorted_total_scores[player_1].score))
        rendering.set_text(render_ids.player_1_overall_score_last_value, player_last_scores[player_1] and math.ceil(player_last_scores[player_1]))
        rendering.set_text(render_ids.player_1_total_kills_total_value, player_1_stats.total.kills)
        rendering.set_text(render_ids.player_1_total_kills_last_value, player_1_stats.last_attempt.kills)
        rendering.set_text(render_ids.player_1_total_deaths_total_value, player_1_stats.total.deaths)
        rendering.set_text(render_ids.player_1_total_deaths_last_value, player_1_stats.last_attempt.deaths)
        rendering.set_text(render_ids.player_1_top_kills_per_minute_total_value, player_1_stats.total.top_kills_per_minute)
        rendering.set_text(render_ids.player_1_top_kills_per_minute_last_value, player_1_stats.last_attempt.top_kills_per_minute)
        rendering.set_text(render_ids.player_1_arena_attempts_total_value, player_1_stats.total.attempts)
        rendering.set_text(render_ids.player_1_arena_attempts_last_value, player_1_stats.last_attempt.attempts)
        rendering.set_text(render_ids.player_1_arena_victories_total_value, player_1_stats.total.victories)
        rendering.set_text(render_ids.player_1_arena_victories_last_value, player_1_stats.last_attempt.victories)
    end
    if player_2 then
        for name, render_id in pairs(render_ids) do
            if name:find("player_2") and name:find("title") then
                if rendering.is_valid(render_id) then
                    rendering.set_color(render_id, players[player_2].chat_color)
                end
            end
        end
        rendering.set_text(render_ids.player_2_name, players[player_2].name)
        rendering.set_color(render_ids.player_2_name, players[player_2].chat_color)
        rendering.set_text(render_ids.player_2_overall_score_total_value, sorted_total_scores[player_2] and math.ceil(sorted_total_scores[player_2].score))
        rendering.set_text(render_ids.player_2_overall_score_last_value, player_last_scores[player_2] and math.ceil(player_last_scores[player_2]))
        rendering.set_text(render_ids.player_2_total_kills_total_value, player_2_stats.total.kills)
        rendering.set_text(render_ids.player_2_total_kills_last_value, player_2_stats.last_attempt.kills)
        rendering.set_text(render_ids.player_2_total_deaths_total_value, player_2_stats.total.deaths)
        rendering.set_text(render_ids.player_2_total_deaths_last_value, player_2_stats.last_attempt.deaths)
        rendering.set_text(render_ids.player_2_top_kills_per_minute_total_value, player_2_stats.total.top_kills_per_minute)
        rendering.set_text(render_ids.player_2_top_kills_per_minute_last_value, player_2_stats.last_attempt.top_kills_per_minute)
        rendering.set_text(render_ids.player_2_arena_attempts_total_value, player_2_stats.total.attempts)
        rendering.set_text(render_ids.player_2_arena_attempts_last_value, player_2_stats.last_attempt.attempts)
        rendering.set_text(render_ids.player_2_arena_victories_total_value, player_2_stats.total.victories)
        rendering.set_text(render_ids.player_2_arena_victories_last_value, player_2_stats.last_attempt.victories)
    end
    if player_3 then
        for name, render_id in pairs(render_ids) do
            if name:find("player_3") and name:find("title") then
                if rendering.is_valid(render_id) then
                    rendering.set_color(render_id, players[player_3].chat_color)
                end
            end
        end
        rendering.set_text(render_ids.player_3_name, players[player_3].name)
        rendering.set_color(render_ids.player_3_name, players[player_3].chat_color)
        rendering.set_text(render_ids.player_3_overall_score_total_value, sorted_total_scores[player_3] and math.ceil(sorted_total_scores[player_3].score))
        rendering.set_text(render_ids.player_3_overall_score_last_value, player_last_scores[player_3] and math.ceil(player_last_scores[player_3]))
        rendering.set_text(render_ids.player_3_total_kills_total_value, player_3_stats.total.kills)
        rendering.set_text(render_ids.player_3_total_kills_last_value, player_3_stats.last_attempt.kills)
        rendering.set_text(render_ids.player_3_total_deaths_total_value, player_3_stats.total.deaths)
        rendering.set_text(render_ids.player_3_total_deaths_last_value, player_3_stats.last_attempt.deaths)
        rendering.set_text(render_ids.player_3_top_kills_per_minute_total_value, player_3_stats.total.top_kills_per_minute)
        rendering.set_text(render_ids.player_3_top_kills_per_minute_last_value, player_3_stats.last_attempt.top_kills_per_minute)
        rendering.set_text(render_ids.player_3_arena_attempts_total_value, player_3_stats.total.attempts)
        rendering.set_text(render_ids.player_3_arena_attempts_last_value, player_3_stats.last_attempt.attempts)
        rendering.set_text(render_ids.player_3_arena_victories_total_value, player_3_stats.total.victories)
        rendering.set_text(render_ids.player_3_arena_victories_last_value, player_3_stats.last_attempt.victories)
    end
end

local function initialize_statistics()

    local render_ids = global.statistics_render_ids
    local lobby_surface = game.surfaces.lobby
    local stat_title_x = -40
    local stat_title_y = -12
    if not render_ids then
        global.statistics_render_ids = {
            title = rendering.draw_text{
                text = "Statistics",
                surface = lobby_surface,
                target = {x = stat_title_x + 7.5, y = stat_title_y - 4},
                color = {r = 1, g = 1, b = 1},
                alignment = "center",
                scale = 4,
            },
            title_total = rendering.draw_text{
                text = "Total",
                surface = lobby_surface,
                target = {x = stat_title_x + 10, y = stat_title_y + 23},
                color = {r = 1, g = 1, b = 1},
                alignment = "right",
                scale = 2,
            },
            title_last = rendering.draw_text{
                text = "Last",
                surface = lobby_surface,
                target = {x = stat_title_x + 15, y = stat_title_y + 23},
                color = {r = 1, g = 1, b = 1},
                alignment = "right",
                scale = 2,
            },
            player_1_name = rendering.draw_text{
                text = "Player 1",
                surface = lobby_surface,
                target = {x = stat_title_x, y = stat_title_y - 0},
                color = {r = 1, g = 1, b = 1},
                alignment = "left",
                vertical_alignment = "middle",
                scale = 4,
            },
            player_1_overall_score_title = rendering.draw_text{
                text = "Overall Score:",
                surface = lobby_surface,
                target = {x = stat_title_x, y = stat_title_y + 1},
                color = {r = 1, g = 1, b = 1},
                alignment = "left",
                scale = 2,
            },
            player_1_overall_score_total_value = rendering.draw_text{
                text = "0",
                surface = lobby_surface,
                target = {x = stat_title_x + 10, y = stat_title_y + 1},
                color = {r = 1, g = 1, b = 1},
                alignment = "right",
                scale = 2,
            },
            player_1_overall_score_last_value = rendering.draw_text{
                text = "0",
                surface = lobby_surface,
                target = {x = stat_title_x + 15, y = stat_title_y + 1},
                color = {r = 1, g = 1, b = 1},
                alignment = "right",
                scale = 2,
            },
            player_1_total_kills_title = rendering.draw_text{
                text = "Arena Kills:",
                surface = lobby_surface,
                target = {x = stat_title_x, y = stat_title_y + 2},
                color = {r = 1, g = 1, b = 1},
                alignment = "left",
                scale = 2,
            },
            player_1_total_kills_total_value = rendering.draw_text{
                text = "0",
                surface = lobby_surface,
                target = {x = stat_title_x + 10, y = stat_title_y + 2},
                color = {r = 1, g = 1, b = 1},
                alignment = "right",
                scale = 2,
            },
            player_1_total_kills_last_value = rendering.draw_text{
                text = "0",
                surface = lobby_surface,
                target = {x = stat_title_x + 15, y = stat_title_y + 2},
                color = {r = 1, g = 1, b = 1},
                alignment = "right",
                scale = 2,
            },
            player_1_total_deaths_title = rendering.draw_text{
                text = "Arena Deaths:",
                surface = lobby_surface,
                target = {x = stat_title_x, y = stat_title_y + 3},
                color = {r = 1, g = 1, b = 1},
                alignment = "left",
                scale = 2,
            },
            player_1_total_deaths_total_value = rendering.draw_text{
                text = "0",
                surface = lobby_surface,
                target = {x = stat_title_x + 10, y = stat_title_y + 3},
                color = {r = 1, g = 1, b = 1},
                alignment = "right",
                scale = 2,
            },
            player_1_total_deaths_last_value = rendering.draw_text{
                text = "0",
                surface = lobby_surface,
                target = {x = stat_title_x + 15, y = stat_title_y + 3},
                color = {r = 1, g = 1, b = 1},
                alignment = "right",
                scale = 2,
            },
            player_1_top_kills_per_minute_title = rendering.draw_text{
                text = "Top Kills/Minute:",
                surface = lobby_surface,
                target = {x = stat_title_x, y = stat_title_y + 4},
                color = {r = 1, g = 1, b = 1},
                alignment = "left",
                scale = 2,
            },
            player_1_top_kills_per_minute_total_value = rendering.draw_text{
                text = "0",
                surface = lobby_surface,
                target = {x = stat_title_x + 10, y = stat_title_y + 4},
                color = {r = 1, g = 1, b = 1},
                alignment = "right",
                scale = 2,
            },
            player_1_top_kills_per_minute_last_value = rendering.draw_text{
                text = "0",
                surface = lobby_surface,
                target = {x = stat_title_x + 15, y = stat_title_y + 4},
                color = {r = 1, g = 1, b = 1},
                alignment = "right",
                scale = 2,
            },
            player_1_arena_attempts_title = rendering.draw_text{
                text = "Arena Attempts:",
                surface = lobby_surface,
                target = {x = stat_title_x, y = stat_title_y + 5},
                color = {r = 1, g = 1, b = 1},
                alignment = "left",
                scale = 2,
            },
            player_1_arena_attempts_total_value = rendering.draw_text{
                text = "0",
                surface = lobby_surface,
                target = {x = stat_title_x + 10, y = stat_title_y + 5},
                color = {r = 1, g = 1, b = 1},
                alignment = "right",
                scale = 2,
            },
            player_1_arena_attempts_last_value = rendering.draw_text{
                text = "0",
                surface = lobby_surface,
                target = {x = stat_title_x + 15, y = stat_title_y + 5},
                color = {r = 1, g = 1, b = 1},
                alignment = "right",
                scale = 2,
            },
            player_1_arena_victories_title = rendering.draw_text{
                text = "Arena Victories:",
                surface = lobby_surface,
                target = {x = stat_title_x, y = stat_title_y + 6},
                color = {r = 1, g = 1, b = 1},
                alignment = "left",
                scale = 2,
            },
            player_1_arena_victories_total_value = rendering.draw_text{
                text = "0",
                surface = lobby_surface,
                target = {x = stat_title_x + 10, y = stat_title_y + 6},
                color = {r = 1, g = 1, b = 1},
                alignment = "right",
                scale = 2,
            },
            player_1_arena_victories_last_value = rendering.draw_text{
                text = "0",
                surface = lobby_surface,
                target = {x = stat_title_x + 15, y = stat_title_y + 6},
                color = {r = 1, g = 1, b = 1},
                alignment = "right",
                scale = 2,
            },
            player_2_name = rendering.draw_text{
                text = "Player 2",
                surface = lobby_surface,
                target = {x = stat_title_x, y = stat_title_y + 8},
                color = {r = 1, g = 1, b = 1},
                alignment = "left",
                vertical_alignment = "middle",
                scale = 4,
            },
            player_2_overall_score_title = rendering.draw_text{
                text = "Overall Score:",
                surface = lobby_surface,
                target = {x = stat_title_x, y = stat_title_y + 9},
                color = {r = 1, g = 1, b = 1},
                alignment = "left",
                scale = 2,
            },
            player_2_overall_score_total_value = rendering.draw_text{
                text = "0",
                surface = lobby_surface,
                target = {x = stat_title_x + 10, y = stat_title_y + 9},
                color = {r = 1, g = 1, b = 1},
                alignment = "right",
                scale = 2,
            },
            player_2_overall_score_last_value = rendering.draw_text{
                text = "0",
                surface = lobby_surface,
                target = {x = stat_title_x + 15, y = stat_title_y + 9},
                color = {r = 1, g = 1, b = 1},
                alignment = "right",
                scale = 2,
            },
            player_2_total_kills_title = rendering.draw_text{
                text = "Arena Kills:",
                surface = lobby_surface,
                target = {x = stat_title_x, y = stat_title_y + 10},
                color = {r = 1, g = 1, b = 1},
                alignment = "left",
                scale = 2,
            },
            player_2_total_kills_total_value = rendering.draw_text{
                text = "0",
                surface = lobby_surface,
                target = {x = stat_title_x + 10, y = stat_title_y + 10},
                color = {r = 1, g = 1, b = 1},
                alignment = "right",
                scale = 2,
            },
            player_2_total_kills_last_value = rendering.draw_text{
                text = "0",
                surface = lobby_surface,
                target = {x = stat_title_x + 15, y = stat_title_y + 10},
                color = {r = 1, g = 1, b = 1},
                alignment = "right",
                scale = 2,
            },
            player_2_total_deaths_title = rendering.draw_text{
                text = "Arena Deaths:",
                surface = lobby_surface,
                target = {x = stat_title_x, y = stat_title_y + 11},
                color = {r = 1, g = 1, b = 1},
                alignment = "left",
                scale = 2,
            },
            player_2_total_deaths_total_value = rendering.draw_text{
                text = "0",
                surface = lobby_surface,
                target = {x = stat_title_x + 10, y = stat_title_y + 11},
                color = {r = 1, g = 1, b = 1},
                alignment = "right",
                scale = 2,
            },
            player_2_total_deaths_last_value = rendering.draw_text{
                text = "0",
                surface = lobby_surface,
                target = {x = stat_title_x + 15, y = stat_title_y + 11},
                color = {r = 1, g = 1, b = 1},
                alignment = "right",
                scale = 2,
            },
            player_2_top_kills_per_minute_title = rendering.draw_text{
                text = "Top Kills/Minute:",
                surface = lobby_surface,
                target = {x = stat_title_x, y = stat_title_y + 12},
                color = {r = 1, g = 1, b = 1},
                alignment = "left",
                scale = 2,
            },
            player_2_top_kills_per_minute_total_value = rendering.draw_text{
                text = "0",
                surface = lobby_surface,
                target = {x = stat_title_x + 10, y = stat_title_y + 12},
                color = {r = 1, g = 1, b = 1},
                alignment = "right",
                scale = 2,
            },
            player_2_top_kills_per_minute_last_value = rendering.draw_text{
                text = "0",
                surface = lobby_surface,
                target = {x = stat_title_x + 15, y = stat_title_y + 12},
                color = {r = 1, g = 1, b = 1},
                alignment = "right",
                scale = 2,
            },
            player_2_arena_attempts_title = rendering.draw_text{
                text = "Arena Attempts:",
                surface = lobby_surface,
                target = {x = stat_title_x, y = stat_title_y + 13},
                color = {r = 1, g = 1, b = 1},
                alignment = "left",
                scale = 2,
            },
            player_2_arena_attempts_total_value = rendering.draw_text{
                text = "0",
                surface = lobby_surface,
                target = {x = stat_title_x + 10, y = stat_title_y + 13},
                color = {r = 1, g = 1, b = 1},
                alignment = "right",
                scale = 2,
            },
            player_2_arena_attempts_last_value = rendering.draw_text{
                text = "0",
                surface = lobby_surface,
                target = {x = stat_title_x + 15, y = stat_title_y + 13},
                color = {r = 1, g = 1, b = 1},
                alignment = "right",
                scale = 2,
            },
            player_2_arena_victories_title = rendering.draw_text{
                text = "Arena Victories:",
                surface = lobby_surface,
                target = {x = stat_title_x, y = stat_title_y + 14},
                color = {r = 1, g = 1, b = 1},
                alignment = "left",
                scale = 2,
            },
            player_2_arena_victories_total_value = rendering.draw_text{
                text = "0",
                surface = lobby_surface,
                target = {x = stat_title_x + 10, y = stat_title_y + 14},
                color = {r = 1, g = 1, b = 1},
                alignment = "right",
                scale = 2,
            },
            player_2_arena_victories_last_value = rendering.draw_text{
                text = "0",
                surface = lobby_surface,
                target = {x = stat_title_x + 15, y = stat_title_y + 14},
                color = {r = 1, g = 1, b = 1},
                alignment = "right",
                scale = 2,
            },
            player_3_name = rendering.draw_text{
                text = "Player 3",
                surface = lobby_surface,
                target = {x = stat_title_x, y = stat_title_y + 16},
                color = {r = 1, g = 1, b = 1},
                alignment = "left",
                vertical_alignment = "middle",
                scale = 4,
            },
            player_3_overall_score_title = rendering.draw_text{
                text = "Overall Score:",
                surface = lobby_surface,
                target = {x = stat_title_x, y = stat_title_y + 17},
                color = {r = 1, g = 1, b = 1},
                alignment = "left",
                scale = 2,
            },
            player_3_overall_score_total_value = rendering.draw_text{
                text = "0",
                surface = lobby_surface,
                target = {x = stat_title_x + 10, y = stat_title_y + 17},
                color = {r = 1, g = 1, b = 1},
                alignment = "right",
                scale = 2,
            },
            player_3_overall_score_last_value = rendering.draw_text{
                text = "0",
                surface = lobby_surface,
                target = {x = stat_title_x + 15, y = stat_title_y + 17},
                color = {r = 1, g = 1, b = 1},
                alignment = "right",
                scale = 2,
            },
            player_3_total_kills_title = rendering.draw_text{
                text = "Arena Kills:",
                surface = lobby_surface,
                target = {x = stat_title_x, y = stat_title_y + 18},
                color = {r = 1, g = 1, b = 1},
                alignment = "left",
                scale = 2,
            },
            player_3_total_kills_total_value = rendering.draw_text{
                text = "0",
                surface = lobby_surface,
                target = {x = stat_title_x + 10, y = stat_title_y + 18},
                color = {r = 1, g = 1, b = 1},
                alignment = "right",
                scale = 2,
            },
            player_3_total_kills_last_value = rendering.draw_text{
                text = "0",
                surface = lobby_surface,
                target = {x = stat_title_x + 15, y = stat_title_y + 18},
                color = {r = 1, g = 1, b = 1},
                alignment = "right",
                scale = 2,
            },
            player_3_total_deaths_title = rendering.draw_text{
                text = "Arena Deaths:",
                surface = lobby_surface,
                target = {x = stat_title_x, y = stat_title_y + 19},
                color = {r = 1, g = 1, b = 1},
                alignment = "left",
                scale = 2,
            },
            player_3_total_deaths_total_value = rendering.draw_text{
                text = "0",
                surface = lobby_surface,
                target = {x = stat_title_x + 10, y = stat_title_y + 19},
                color = {r = 1, g = 1, b = 1},
                alignment = "right",
                scale = 2,
            },
            player_3_total_deaths_last_value = rendering.draw_text{
                text = "0",
                surface = lobby_surface,
                target = {x = stat_title_x + 15, y = stat_title_y + 19},
                color = {r = 1, g = 1, b = 1},
                alignment = "right",
                scale = 2,
            },
            player_3_top_kills_per_minute_title = rendering.draw_text{
                text = "Top Kills/Minute:",
                surface = lobby_surface,
                target = {x = stat_title_x, y = stat_title_y + 20},
                color = {r = 1, g = 1, b = 1},
                alignment = "left",
                scale = 2,
            },
            player_3_top_kills_per_minute_total_value = rendering.draw_text{
                text = "0",
                surface = lobby_surface,
                target = {x = stat_title_x + 10, y = stat_title_y + 20},
                color = {r = 1, g = 1, b = 1},
                alignment = "right",
                scale = 2,
            },
            player_3_top_kills_per_minute_last_value = rendering.draw_text{
                text = "0",
                surface = lobby_surface,
                target = {x = stat_title_x + 15, y = stat_title_y + 20},
                color = {r = 1, g = 1, b = 1},
                alignment = "right",
                scale = 2,
            },
            player_3_arena_attempts_title = rendering.draw_text{
                text = "Arena Attempts:",
                surface = lobby_surface,
                target = {x = stat_title_x, y = stat_title_y + 21},
                color = {r = 1, g = 1, b = 1},
                alignment = "left",
                scale = 2,
            },
            player_3_arena_attempts_total_value = rendering.draw_text{
                text = "0",
                surface = lobby_surface,
                target = {x = stat_title_x + 10, y = stat_title_y + 21},
                color = {r = 1, g = 1, b = 1},
                alignment = "right",
                scale = 2,
            },
            player_3_arena_attempts_last_value = rendering.draw_text{
                text = "0",
                surface = lobby_surface,
                target = {x = stat_title_x + 15, y = stat_title_y + 21},
                color = {r = 1, g = 1, b = 1},
                alignment = "right",
                scale = 2,
            },
            player_3_arena_victories_title = rendering.draw_text{
                text = "Arena Victories:",
                surface = lobby_surface,
                target = {x = stat_title_x, y = stat_title_y + 22},
                color = {r = 1, g = 1, b = 1},
                alignment = "left",
                scale = 2,
            },
            player_3_arena_victories_total_value = rendering.draw_text{
                text = "0",
                surface = lobby_surface,
                target = {x = stat_title_x + 10, y = stat_title_y + 22},
                color = {r = 1, g = 1, b = 1},
                alignment = "right",
                scale = 2,
            },
            player_3_arena_victories_last_value = rendering.draw_text{
                text = "0",
                surface = lobby_surface,
                target = {x = stat_title_x + 15, y = stat_title_y + 22},
                color = {r = 1, g = 1, b = 1},
                alignment = "right",
                scale = 2,
            },
        }
        update_statistics()
    end
end

---@param player_index uint
local function new_attempt_stats_reset(player_index)
    global.statistics = global.statistics or {}
    local player_stats = global.statistics[player_index] --[[@type player_statistics]]
    if player_stats then
        player_stats.total.attempts = player_stats.total.attempts + 1
        player_stats.last_attempt.attempts = 1
        player_stats.last_attempt.kills = 0
        player_stats.last_attempt.deaths = 0
        player_stats.last_attempt.damage_dealt = 0
        player_stats.last_attempt.damage_taken = 0
        player_stats.last_attempt.damage_healed = 0
        player_stats.last_attempt.top_kills_per_minute = 0
        player_stats.last_attempt.victories = 0
    end
end

local function initialize_player_statistics(player_index)
    global.statistics = global.statistics or {} --[[@type table<uint, player_statistics>]]
    global.statistics[player_index] = global.statistics[player_index] or {
        total = {
            kills = 0,
            deaths = 0,
            damage_dealt = 0,
            damage_taken = 0,
            damage_healed = 0,
            attempts = 0,
            victories = 0,
            top_kills_per_minute = 0,
        },
        last_attempt = {
            kills = 0,
            deaths = 0,
            damage_dealt = 0,
            damage_taken = 0,
            damage_healed = 0,
            attempts = 0,
            victories = 0,
            top_kills_per_minute = 0,
        },
    }
end

return {
    update_statistics = update_statistics,
    initialize_statistics = initialize_statistics,
    new_attempt_stats_reset = new_attempt_stats_reset,
    initialize_player_statistics = initialize_player_statistics,
}
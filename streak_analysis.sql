
------------ UPDATED Version with Pre_Aggregation ----------------

WITH cte AS (
    SELECT 
        player_id, 
        match_date, 
        match_result,
        CASE WHEN match_result = 'W' THEN 1 ELSE 0 END AS win_flag
    FROM player_results
),

streak_cte AS (
    SELECT 
        player_id, 
        match_date, 
        match_result,
        win_flag,
        SUM(CASE WHEN win_flag = 0 THEN 1 ELSE 0 END) 
            OVER (PARTITION BY player_id ORDER BY match_date) AS loss_group,
        SUM(CASE WHEN win_flag = 1 THEN 1 ELSE 0 END) 
            OVER (PARTITION BY player_id ORDER BY match_date) AS win_group
    FROM cte
),

winning_streak_summary AS (
    SELECT 
        player_id, 
        loss_group,
        COUNT(*) AS matches_in_group,
        SUM(CASE WHEN win_flag = 1 THEN 1 ELSE 0 END) AS winning_streak_count
    FROM streak_cte
    GROUP BY player_id, loss_group
	order by player_id, loss_group
),

---select * from winning_streak_summary

losing_streak_summary AS (
    SELECT 
        player_id, 
        win_group,
        COUNT(*) AS matches_in_group,
        SUM(CASE WHEN win_flag = 0 THEN 1 ELSE 0 END) AS losing_streak_count
    FROM streak_cte
    GROUP BY player_id, win_group
	ORDER BY player_id, win_group
),


winning_max as(

select player_id, max(winning_streak_count) as win_max
from winning_streak_summary
group by player_id
order by player_id
),

losing_max as(

select player_id, max(losing_streak_count) as lost_max
from losing_streak_summary
group by player_id
order by player_id
),

---select * from losing_max
---select * from winning_max

--- select * from losing_streak_summary

totals AS (
    SELECT 
        player_id,
        COUNT(*) AS total_matches_played,
        SUM(CASE WHEN win_flag = 1 THEN 1 ELSE 0 END) AS total_matches_won,
        SUM(CASE WHEN win_flag = 0 THEN 1 ELSE 0 END) AS total_matches_lost
    FROM cte
    GROUP BY player_id
)

---select * from totals

SELECT 
    t.player_id,
    t.total_matches_played,
    t.total_matches_won,
    t.total_matches_lost,
    COALESCE((w.win_max), 0) AS max_winning_streak,
    COALESCE((l.lost_max), 0) AS max_losing_streak
FROM totals t
LEFT JOIN winning_max w ON t.player_id = w.player_id
LEFT JOIN losing_max l ON t.player_id = l.player_id
/*
GROUP BY 
    t.player_id, 
    t.total_matches_played, 
    t.total_matches_won, 
    t.total_matches_lost,
	w.win_max,
	l.lost_max

	*/
ORDER BY t.player_id;

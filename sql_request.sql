WITH session_calculation AS (
	SELECT user_id, 
		event, 
        event_time, 
        value,
        LAG(event_time) OVER (PARTITION BY user_id ORDER BY event_time) AS prev_event_time
	FROM logs)
WITH window_numeric AS (
	SELECT user_id, 
			event, 
			event_time, 
			value,
			SUM(
				CASE
					WHEN event_time <= prev_event_time + INTERVAL ('5 minutes') THEN 0
					ELSE 1
				END
			) OVER (PARTITION BY user_id ORDER BY event_time) AS window_id
	FROM session_calculation)
WITH result AS (
	SELECT user_id, 
				event, 
				event_time, 
				value,
				SUM(
					CASE
						WHEN LAG(value) = value THEN 1
						ELSE 0
					END
				) OVER (PARTITION BY user_id ORDER BY event_time) AS count_duplicates
	fROM window_numeric)
SELECT value,
	MAX(count_duplicates)
FROM result
WHERE count_duplicates >= 2
GROUP BY value
ORDER BY count_duplicates DESC
LIMIT 5;

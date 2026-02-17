SELECT partition_0, year, month, day, count(eventid) AS daily_count FROM "{{db}}"."{{table}}"
WHERE 
    year = ? 
    AND month = ? 
    AND day = ?
    AND eventid IS NOT NULL
GROUP BY partition_0, year, month, day

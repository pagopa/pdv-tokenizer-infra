SELECT partition_0, year, month, day, count(distinct(eventid)) AS daily_count FROM "{{db}}"."{{table}}"
WHERE 
    year = ? 
    AND month = ? 
    AND day = ?
GROUP BY partition_0, year, month, day

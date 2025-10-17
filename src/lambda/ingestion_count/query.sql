SELECT partition_0, year, month, day, count(*) AS daily_count FROM "{{db}}"."{{table}}"
WHERE 
    year = ? 
    AND month = ? 
    AND day = ?
GROUP BY partition_0, year, month, day

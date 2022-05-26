CREATE OR REPLACE VDS 
QueryAnalysis.Application.OverallWorkloadDistribution 
AS 
WITH t1 AS ( 
    SELECT 
    TO_DATE("start" / 1000) queryStartDate, 
    DATE_PART('hour', TO_TIMESTAMP("start" / 1000)) queryStartHour, 
    "start" / 1000 queryStartSecond, 
    COUNT(*) queriesPerSecond 
    FROM QueryAnalysis.Preparation.results 
    GROUP BY queryStartDate, queryStartHour, queryStartSecond 
    ) 
SELECT 
queryStartDate, 
queryStartHour, 
SUM(queriesPerSecond) queriesPerHour, 
MAX(queriesPerSecond) peakQueriesPerSecond 
FROM t1 
GROUP BY queryStartDate, queryStartHour 
ORDER BY queryStartDate DESC, queryStartHour
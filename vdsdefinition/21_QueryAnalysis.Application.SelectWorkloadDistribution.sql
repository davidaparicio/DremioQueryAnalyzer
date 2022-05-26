CREATE OR REPLACE VDS 
QueryAnalysis.Application.SelectWorkloadDistribution 
AS 
WITH t1 AS ( 
    SELECT 
        TO_DATE("startTime") queryStartDate, 
        DATE_PART('hour', "StartTime") queryStartHour, 
        DATE_TRUNC('second', "startTime") AS queryStartSecond, 
        COUNT(*) queriesPerSecond 
    FROM QueryAnalysis.Business.SelectQueryData 
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
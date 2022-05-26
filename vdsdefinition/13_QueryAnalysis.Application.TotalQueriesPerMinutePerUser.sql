CREATE OR REPLACE VDS 
QueryAnalysis.Application.TotalQueriesPerMinutePerUser  
AS 
SELECT 
    DATE_TRUNC('minute', startTime) AS startMinute, 
    username, 
    outcome, 
    COUNT(*) AS queriesPerMinute 
FROM QueryAnalysis.Business.SelectQueryData 
GROUP BY startMinute, username, outcome 
ORDER BY startMinute, username, outcome ASC
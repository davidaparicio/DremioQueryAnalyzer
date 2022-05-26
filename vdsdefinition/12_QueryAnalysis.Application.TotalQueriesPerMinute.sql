CREATE OR REPLACE VDS 
QueryAnalysis.Application.TotalQueriesPerMinute  
AS 
SELECT 
    DATE_TRUNC('minute', startTime) AS startMinute, 
    COUNT(*) AS queriesPerMinute 
FROM QueryAnalysis.Business.SelectQueryData 
GROUP BY startMinute 
ORDER BY startMinute ASC
CREATE OR REPLACE VDS 
QueryAnalysis.Application.QueryConcurrencyCount 
AS 
SELECT 
  thisQueryId, 
  count(thisQueryId) AS concurrency 
FROM QueryAnalysis.Application.QueryConcurrency 
GROUP BY thisQueryId 
ORDER BY concurrency desc
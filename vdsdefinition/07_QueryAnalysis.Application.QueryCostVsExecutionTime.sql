CREATE OR REPLACE VDS 
QueryAnalysis.Application.QueryCostVsExecutionTime  
AS 
SELECT queryId, queryText, executionTime, queryCost, accelerated 
FROM QueryAnalysis.Business.SelectQueryData 
WHERE requestType = 'RUN_SQL' 
AND outcome = 'COMPLETED' 
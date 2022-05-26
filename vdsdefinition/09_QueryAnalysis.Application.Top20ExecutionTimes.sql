CREATE OR REPLACE VDS 
QueryAnalysis.Application.Top20ExecutionTimes  
AS 
SELECT * FROM QueryAnalysis.Business.SelectQueryData 
WHERE executionTime IS NOT NULL 
ORDER BY executionTime DESC 
LIMIT 20
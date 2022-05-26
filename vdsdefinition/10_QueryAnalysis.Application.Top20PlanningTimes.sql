CREATE OR REPLACE VDS 
QueryAnalysis.Application.Top20PlanningTimes  
AS 
SELECT * FROM QueryAnalysis.Business.SelectQueryData
WHERE planningTime IS NOT NULL 
ORDER BY planningTime DESC 
LIMIT 20
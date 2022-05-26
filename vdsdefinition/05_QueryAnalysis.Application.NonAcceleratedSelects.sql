CREATE OR REPLACE VDS 
QueryAnalysis.Application.NonAcceleratedSelects  
AS 
SELECT * FROM QueryAnalysis.Business.SelectQueryData 
WHERE accelerated = FALSE 
AND totalDurationMS > 1000 
ORDER BY totalDurationMS DESC
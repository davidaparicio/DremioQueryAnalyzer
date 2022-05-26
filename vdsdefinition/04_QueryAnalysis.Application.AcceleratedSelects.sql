CREATE OR REPLACE VDS 
QueryAnalysis.Application.AcceleratedSelects 
AS 
SELECT * FROM QueryAnalysis.Business.SelectQueryData 
WHERE accelerated = true
CREATE OR REPLACE VDS 
QueryAnalysis.Application.QueriesNotCompleted  
AS 
SELECT * FROM QueryAnalysis.Business.SelectQueryData 
WHERE outcome NOT IN ('COMPLETED')
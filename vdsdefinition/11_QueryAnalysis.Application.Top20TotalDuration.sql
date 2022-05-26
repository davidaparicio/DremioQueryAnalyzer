CREATE OR REPLACE VDS 
QueryAnalysis.Application.Top20TotalDuration  
AS 
SELECT * FROM QueryAnalysis.Business.SelectQueryData 
ORDER BY totalDurationMS DESC 
LIMIT 20
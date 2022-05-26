CREATE OR REPLACE VDS 
QueryAnalysis.Application.PctAccelerated  
AS 
SELECT 
	SUM(CASE WHEN "accelerated" = 'true' THEN 1 ELSE 0 END) AS "acceleratedCount", 
	SUM(CASE WHEN "accelerated" = 'true' THEN 1 ELSE 0 END) / CAST(COUNT(*) AS FLOAT) * 100 AS "pctAccelerated" 
FROM QueryAnalysis.Business.SelectQueryData 
WHERE "outcome" = 'COMPLETED'
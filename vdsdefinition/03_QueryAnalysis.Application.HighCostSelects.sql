CREATE OR REPLACE VDS 
QueryAnalysis.Application.HighCostSelects 
AS 
SELECT * FROM QueryAnalysis.Business.SelectQueryData 
WHERE queueName = 'High Cost User Queries'
CREATE OR REPLACE VDS 
QueryAnalysis.Application.QueryThresholds_2Queues 
AS 
SELECT 
    max(case when a.pct = 80 then a.queryCost else 0 end) as upper_low_cost_threshold
FROM 
    (SELECT 
        queryCost, 
        NTILE(100) OVER(ORDER BY queryCost ASC) as pct 
    FROM QueryAnalysis.Business.SelectQueryData 
    WHERE "outcome" = 'COMPLETED' 
    AND requestType IN ('RUN_SQL', 'EXECUTE_PREPARE') 
    AND queryCost > 10 AND queueName != 'UI Previews') a
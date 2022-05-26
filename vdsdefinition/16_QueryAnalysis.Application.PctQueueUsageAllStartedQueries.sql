CREATE OR REPLACE VDS 
QueryAnalysis.Application.PctQueueUsageAllStartedQueries  
AS 
SELECT 
    queueName, 
    COUNT("queueName") AS numQueriesPerQueue, 
    CAST(COUNT("queueName")*100 AS FLOAT) / 
        (SELECT COUNT(*) FROM QueryAnalysis.Business.SelectQueryData 
         WHERE "outcome" IN ('COMPLETED', 'FAILED', 'CANCELED') 
         AND requestType IN ('RUN_SQL', 'EXECUTE_PREPARE') 
         AND executionTime IS NOT NULL 
         AND queryCost > 10) 
FROM QueryAnalysis.Business.SelectQueryData 
WHERE "outcome" IN ('COMPLETED', 'FAILED', 'CANCELED') 
AND requestType IN ('RUN_SQL', 'EXECUTE_PREPARE') 
AND executionTime IS NOT NULL 
AND queryCost > 10 
GROUP BY queueName
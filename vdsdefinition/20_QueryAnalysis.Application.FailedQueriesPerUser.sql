CREATE OR REPLACE VDS 
QueryAnalysis.Application.FailedQueriesPerUser 
AS 
SELECT 
    TO_DATE("startTime") queryStartDate, 
    username, 
    COUNT(*) failedQueries
FROM QueryAnalysis.Business.SelectQueryData
WHERE OUTCOME = 'FAILED'
GROUP BY username, queryStartDate
ORDER BY queryStartDate DESC, failedQueries DESC
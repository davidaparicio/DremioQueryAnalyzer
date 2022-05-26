CREATE OR REPLACE VDS 
QueryAnalysis.Application.QueueMaxQueriesPerSecond 
AS 
SELECT qc.queueName, MAX(qc.queriesPerSecond) maxQPS 
FROM 
    (SELECT queueName, "DATE_TRUNC"('second', "startTime") AS "startSecond", COUNT(*) AS "queriesPerSecond" 
    FROM "QueryAnalysis"."Business"."SelectQueryData" 
    WHERE queueName != '' and queueName != 'UI Previews' 
    GROUP BY queueName, "startSecond" 
    ORDER BY queueName, "startSecond") qc 
GROUP by qc.queueName 
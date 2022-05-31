CREATE OR REPLACE VDS 
QueryAnalysis.Business.SelectQueryData 
AS 
SELECT *
FROM (SELECT "queryId", "queryText", "queryChunkSizeBytes", "nrQueryChunks", "startTime", "finishTime", 
CAST("totalDurationMS" / 60000.000 AS DECIMAL(10, 3)) AS "totalDurationMinutes", 
CAST("totalDurationMS" / 1000.000 AS DECIMAL(10, 3)) AS "totalDurationSeconds", 
"totalDurationMS", ROW_NUMBER() OVER (ORDER BY "totalDurationMS" DESC) AS "rownumByTotalDurationMS", 
"outcome", "username", "requestType", "queryType", "parentsList", "queueName", "poolWaitTime", "planningTime", 
"enqueuedTime", "executionTime", "accelerated", "inputRecords", "inputBytes", "outputRecords", "outputBytes", 
"queryCost", "outcomereason", "CONCAT"('http://<DREMIO_HOST>:9047/jobs?#', "queryId") AS "profileUrl"
FROM "QueryAnalysis"."Preparation"."results" AS "results"
WHERE "SUBSTR"(UPPER("queryText"), "STRPOS"(UPPER("queryText"), 'SELECT')) LIKE 'SELECT%' AND UPPER("queryText") NOT LIKE 'CREATE TABLE%' 
    AND "requestType" IN ('RUN_SQL', 'EXECUTE_PREPARE')
--AND outcome='COMPLETED'
) AS "t"
WHERE "rownumByTotalDurationMS" > 0


CREATE OR REPLACE VDS 
QueryAnalysis.Business.SelectQueryData 
AS 
/* This VDS allows the user to discard the first N rows because they are exeptional and shouldn't be counted. */
SELECT * FROM (
SELECT 
    queryId, 
    queryTextFirstChunk AS queryText, 
	queryChunkSizeBytes, 
	nrQueryChunks, 
    TO_TIMESTAMP("start"/1000.0) AS startTime,
    CAST("TO_TIMESTAMP"("start" / 1000.0) as DATE) AS startDate,
    TO_TIMESTAMP("finish"/1000.0) AS finishTime, 
    CAST(totalDurationMS/60000.000 AS DECIMAL(10,3)) AS totalDurationMinutes, 
    CAST(totalDurationMS/1000.000 AS DECIMAL(10,3)) AS totalDurationSeconds, 
    "totalDurationMS",
    ROW_NUMBER()OVER(ORDER BY totalDurationMS DESC) as rownumByTotalDurationMS, 
    outcome, 
    username, 
    requestType, 
    queryType, 
    parentsList, 
    queueName, 
    poolWaitTime, 
    planningTime, 
    enqueuedTime, 
    executionTime, 
    accelerated, 
    inputRecords, 
    inputBytes, 
    outputRecords, 
    outputBytes, 
    queryCost,
    outcomereason,
    CONCAT('http://<DREMIO_HOST>:9047/jobs?#', "queryId") AS "profileUrl" 
FROM QueryAnalysis.Preparation.results AS results 
-- We only want select statements 
WHERE SUBSTR(UPPER("queryTextFirstChunk"), STRPOS(UPPER("queryTextFirstChunk"), 'SELECT')) LIKE 'SELECT%'
AND UPPER("queryTextFirstChunk") NOT LIKE 'CREATE TABLE%'
AND requestType in ('RUN_SQL','EXECUTE_PREPARE')
-- If a day in the history has produced bad data, it is better to omit it from your analysis
-- and CAST("TO_TIMESTAMP"("start" / 1000.0) as DATE) > '2022-04-21'
  )t
-- if the top record's totalDurationMS time is way outside of the norm, it is better to omit it from your analysis
 WHERE rownumByTotalDurationMS>0


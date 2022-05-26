CREATE OR REPLACE VDS 
QueryAnalysis.Preparation.results 
AS 
SELECT 
queryId, context, results."start" AS "start", finish, outcome, outcomeReason, UPPER(username) AS username, 
inputRecords, inputBytes, outputRecords, outputBytes, requestType, queryType, parentsList, accelerated, queryCost, 
queueName, poolWaitTime, pendingTime, metadataRetrievalTime, planningTime, engineStartTime, executionPlanningTime, 
startingTime, engineName, enqueuedTime, executionTime, queryChunkSizeBytes, nrQueryChunks, queryTextFirstChunk, 
"results"."finish" - ("results"."start" - "results"."poolWaitTime") AS totalDurationMS
FROM QueriesJson.results

CREATE OR REPLACE VDS 
QueryAnalysis.Preparation.results 
AS
SELECT "queryId",
"TO_TIMESTAMP"("start" / 1000.0) AS "startTime",
"TO_TIMESTAMP"("finish" / 1000.0) AS "finishTime",
  "outcome", "outcomeReason", UPPER("username") AS "username", "inputRecords", "inputBytes", "outputRecords", "outputBytes", "requestType", "queryType", "parentsList", "accelerated", "queryCost", "queueName", "poolWaitTime", "pendingTime", "metadataRetrievalTime", "planningTime", "engineStartTime", "executionPlanningTime", "startingTime",
"enqueuedTime", "executionTime", "queryChunkSizeBytes", "nrQueryChunks", "queryTextFirstChunk" as queryText, "results"."finish" - ("results"."start" - "results"."poolWaitTime") AS "totalDurationMS"
FROM "QueriesJson"."results"



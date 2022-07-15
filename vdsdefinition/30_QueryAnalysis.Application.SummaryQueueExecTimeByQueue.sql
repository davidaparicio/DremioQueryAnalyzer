create or replace VDS QueryAnalysis.Application.SummaryQueueExecTimeByQueue
as
WITH "T1" AS (SELECT "queueName", 1 AS "QueryCount",
        CASE WHEN COALESCE("enqueuedTime") / 1000 <= 0 THEN 0 ELSE 1 END AS "WaitQuery",
        COALESCE("enqueuedTime", 0) / 1000 AS "QueueTimeSec",
        COALESCE("executionTime", 0) / 1000 AS "ExecTimeSec"
FROM "QueryAnalysis"."Business"."SelectQueryData"
WHERE "queueName" <> '' AND "outcome" = 'COMPLETED')
(SELECT "queueName", SUM("QueryCount") AS "TotalQueryCount",
    SUM("WaitQuery") AS "QueuedQueries",
    100 * SUM("WaitQuery") / SUM("QueryCount") AS "PercentageQueued",
    MAX("QueueTimeSec") AS "MaxQueueTimeSec",
    MAX("ExecTimeSec") AS "MaxExecTimeSec",
    MAX("QueueTimeSec") / 60 AS "MaxQueueTimeMinutes",
    MAX("ExecTimeSec") / 60 AS "MaxExecTimeMinutes"
FROM "T1"
GROUP BY "queueName")
ORDER BY 2 DESC


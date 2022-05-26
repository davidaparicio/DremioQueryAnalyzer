create or replace VDS QueryAnalysis.Application.SummaryQueueExecTimeByQueue
as
WITH T1 as
(SELECT queueName, 
        1 as QueryCount , 
    case WHEN (coalesce(enqueuedTime)/1000) <= 0 THEN 0
         ELSE 1 end WaitQuery,
    coalesce(enqueuedTime,0)/1000 as QueueTimeSec,
    coalesce(executionTime,0)/1000 as ExecTimeSec
FROM "QueryAnalysis"."Business".SelectQueryData 
 where queueName <> ''
  and outcome = 'COMPLETED'
)
SELECT queueName, 
       SUM(QueryCount) as TotalQueryCount, 
       SUM(WaitQuery) as QueuedQueries, 
       (100 * SUM(WaitQuery)) / SUM(QueryCount) as PercentageQueued,
       Max(QueueTimeSec) as MaxQueueTimeSec, 
       Max(ExecTimeSec) as  MaxExecTimeSec,
       (Max(QueueTimeSec))/60 as MaxQueueTimeMinutes, 
       (Max(ExecTimeSec))/60 MaxExecTimeMinutes
FROM T1
group by queueName order by 2 desc

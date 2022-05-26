CREATE OR REPLACE VDS 
QueryAnalysis.Application.QueryConcurrency 
AS 
SELECT 
  this.queryId AS thisQueryId, 
  this.queryText as thisQueryText, 
  this.startTime AS thisStartTime, 
  this.finishTime AS thisFinishTime, 
  others.queryId as otherQueryId, 
  others.startTime AS otherStartTime, 
  others.FinishTime AS otherFinishTime, 
  CASE WHEN others.StartTime < this.startTime AND others.finishTime > this.finishTime THEN 'Other Started Before This and Finished After This'
    WHEN others.StartTime < this.startTime AND others.finishTime <= this.finishTime THEN 'Other Started Before This and Finished During This'
    WHEN others.StartTime >= this.startTime AND others.finishTime <= this.FinishTime THEN 'Other Ran During This'
    WHEN others.StartTime >= this.startTime AND others.finishTime > this.FinishTime THEN 'Other Started During This and Finished After This'
  END AS relation 
FROM QueryAnalysis.Business.SelectQueryData this LEFT OUTER JOIN 
  QueryAnalysis.Business.SelectQueryData others 
ON (others.startTime < this.startTime  AND others.FinishTime > this.StartTime) OR 
    (others.StartTime >= this.startTime AND others.startTime <= this.FinishTime) 
AND this.queryId != others.queryId 
AND this."outcome" IN ('COMPLETED', 'FAILED')
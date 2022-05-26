CREATE OR REPLACE VDS 
QueryAnalysis.Application.TotalQueriesStartedPerSecond  
AS 
SELECT 
	DATE_TRUNC('second', "startTime") AS "startSecond", 
	COUNT(*) AS "queriesPerSecond" 
FROM "QueryAnalysis"."Business"."SelectQueryData" 
GROUP BY "startSecond" 
ORDER BY "startSecond"
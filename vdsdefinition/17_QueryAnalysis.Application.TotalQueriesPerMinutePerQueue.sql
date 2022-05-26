CREATE OR REPLACE VDS 
QueryAnalysis.Application.TotalQueriesPerMinutePerQueue  
AS 
SELECT 
	DATE_TRUNC('minute', "startTime") AS "startMinute", 
	queueName, 
	COUNT(*) AS "queriesPerMinute" 
FROM "QueryAnalysis"."Business"."SelectQueryData" 
where queueName != '' 
GROUP BY "startMinute", queueName 
ORDER BY queriesPerMinute desc, "startMinute"
CREATE OR REPLACE VDS 
QueryAnalysis.Application.ActiveUsers 
AS 
SELECT 
	TO_DATE("startTime") queryStartDate, 
	username, 
	COUNT(*) totalQueries, 
	SUM(totalDurationMS) totalWallclockMS 
FROM QueryAnalysis.Business.SelectQueryData 
GROUP BY username, queryStartDate 
ORDER BY queryStartDate DESC, totalQueries DESC, totalWallclockMS DESC
CREATE OR REPLACE VDS 
QueryAnalysis.Application.TotalQueriesPerUser  
AS 
SELECT username, outcome, COUNT(outcome) as countQueries 
FROM QueryAnalysis.Business.SelectQueryData 
GROUP BY username, outcome 
ORDER BY username, outcome
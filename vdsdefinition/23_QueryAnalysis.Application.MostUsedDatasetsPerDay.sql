CREATE OR REPLACE VDS 
QueryAnalysis.Application.MostUsedDatasetsPerDay 
AS 
SELECT 
    queryStartDate, 
    dataset, 
    COUNT(*) totalQueries, 
    COUNT(DISTINCT username) totalUsers 
FROM ( 
    SELECT queryStartDate, CAST(convert_from(convert_to(dataset, 'JSON'), 'UTF8') as VARCHAR) AS dataset, username 
    FROM ( 
        SELECT TO_DATE("start" / 1000) AS queryStartDate, FLATTEN("parentsList") AS dataset, username 
        FROM QueryAnalysis.Preparation.results 
    ) nested_0 
) RawFlattenDataset 
GROUP BY dataset, queryStartDate 
ORDER BY queryStartDate DESC, totalQueries DESC
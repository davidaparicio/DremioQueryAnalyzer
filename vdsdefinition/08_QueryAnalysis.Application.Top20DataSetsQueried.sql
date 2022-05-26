CREATE OR REPLACE VDS 
QueryAnalysis.Application.Top20DataSetsQueried   
AS 
SELECT 
    dataSet, 
    dataSetType, 
    COUNT(*) AS countTimesQueried 
FROM ( 
    SELECT  
        list_to_delimited_string(nested_0.parentsList.datasetPath, '.') AS dataSet, 
        nested_0.parentsList."type" AS dataSetType 
    FROM ( 
        SELECT FLATTEN(parentsList) as parentsList  
        FROM QueryAnalysis.Business.SelectQueryData 
        WHERE parentsList IS NOT NULL 
        AND requestType = 'RUN_SQL' 
     ) nested_0 
) nested_1 
GROUP BY dataSet, dataSetType 
ORDER BY countTimesQueried DESC 
LIMIT 20

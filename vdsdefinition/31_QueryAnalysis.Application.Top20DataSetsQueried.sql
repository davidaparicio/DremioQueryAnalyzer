create or replace VDS QueryAnalysis.Application.Top20DataSetsQueried 
as
SELECT "dataSet", "dataSetType", COUNT(*) AS "countTimesQueried"
FROM (
    SELECT "list_to_delimited_string"("nested_0"."parentsList"."datasetpath", '.') AS "dataSet", 
    "nested_0"."parentsList"."type" AS "dataSetType"
    FROM (
        SELECT "FLATTEN"("parentsList") AS "parentsList"
        FROM "QueryAnalysis"."Business"."SelectQueryData"
        WHERE "parentsList" IS NOT NULL
        ) AS "nested_0"
        ) AS "nested_1"
GROUP BY "dataSet", "dataSetType"
ORDER BY "countTimesQueried" DESC
FETCH NEXT 20 ROWS ONLY


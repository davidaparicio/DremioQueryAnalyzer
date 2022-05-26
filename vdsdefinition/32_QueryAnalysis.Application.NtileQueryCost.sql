create or replace VDS QueryAnalysis.Application.NtileQueryCost 
as
SELECT
pct,max(queryCost) as maxQueryCost
FROM
    (
        SELECT
        queryCost,
        NTILE(100) OVER(ORDER BY queryCost ASC) as pct
    FROM QueryAnalysis.Business.SelectQueryData
    ) a
group by pct
order by pct


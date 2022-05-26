create or replace VDS QueryAnalysis.Application.NtileQueryDuration
as
SELECT
pct,max(totalDurationMS) as maxTotalDurationMS
FROM
    (
        SELECT
        totalDurationMS,
        NTILE(100) OVER(ORDER BY totalDurationMS ASC) as pct
    FROM QueryAnalysis.Business.SelectQueryData
    ) a
group by pct
order by pct


create or replace VDS QueryAnalysis.Application.SummaryByOutcome
as
select outcome, count(*) as QueryCount, 
CAST(count(*) as float)/(select count(*) from "QueryAnalysis"."Business"."SelectQueryData")*100 as Pct 
FROM "QueryAnalysis"."Business"."SelectQueryData"
group by outcome


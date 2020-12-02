select
  trader_name,
  round(directs, -1) as directs,
  round(indirects, -1) as indirects,
  round(total, -1) as total,
  round(indirects / directs, 0) as multiple
from crosstab(
  $$
  select
    case
      when trader_name is null then 'Total' else trader_name
    end,
    case
      when supplier_type is null then 'Total' else supplier_type
    end,
    count(distinct estab_code)::int as count
  from trader_map
  group by rollup(trader_name, supplier_type)
  $$
  )
as result(
  trader_name varchar(20),
  directs int,
  indirects int,
  total int)
where trader_name <> 'Total';

select
  left(s.producer_estab_code, 7) as municipality_code,
  sum(s.animals) as animals
from sales as s
inner join traders as t on
  left(s.buyer_cpf_cnpj, 8) = t.base_cnpj and
  left(s.producer_cpf_cnpj, 8) != t.base_cnpj
where
  s.issue_date between
    '2017-01-01'::date and
    '2019-12-31'::date and
  s.species = 'BOVINA' and
  s.end_use in ('ABATE', 'EXPORTAÇÃO', 'QUARENTENA') and
  s.status <> 'CANCELADA'
group by municipality_code
order by animals desc;

select *
from crosstab($$
  select
    results.bucket,
    results.name,
    sum(results.animals) as animals
  from (
    select
      t.name,
      s.producer_estab_code,
      case
        when sum(s.animals) between 0    and 999  then '0-999'
        when sum(s.animals) between 1000 and 1999 then '1000-1999'
        when sum(s.animals) between 2000 and 2999 then '2000-2999'
        when sum(s.animals) between 3000 and 3999 then '3000-3999'
        when sum(s.animals) between 4000 and 4999 then '4000-4999'
        when sum(s.animals) between 5000 and 5999 then '5000-5999'
        else '6000+'
      end as bucket,
      sum(s.animals) as animals
    from sales as s
    inner join traders as t on
      left(s.buyer_cpf_cnpj, 8) = t.base_cnpj and
      left(s.producer_cpf_cnpj, 8) != t.base_cnpj
    where
      s.issue_date between
        '2017-01-01'::date and
        '2019-12-31'::date and
      s.species = 'BOVINA' and
      s.end_use in ('ABATE', 'EXPORTAÇÃO', 'QUARENTENA') and
      s.status <> 'CANCELADA'
    group by
      producer_estab_code,
      name) as results
  group by results.bucket, results.name
  order by results.bucket desc, results.name;$$)
as ct(
  bucket text,
  "JBS" numeric,
  "Marfrig" numeric,
  "Minerva" numeric
);

select *
from crosstab($$
  select
    case
      when st_area(tm.geom::geography) / 10000 between 0   and 49  then '0–49 ha'
      when st_area(tm.geom::geography) / 10000 between 50  and 99  then '50–99 ha'
      when st_area(tm.geom::geography) / 10000 between 100 and 149 then '100–149 ha'
      when st_area(tm.geom::geography) / 10000 between 150 and 199 then '149–199 ha'
      when st_area(tm.geom::geography) / 10000 between 200 and 249 then '200–249 ha'
      when st_area(tm.geom::geography) / 10000 between 250 and 299 then '250–299 ha'
    else '300+ ha'
    end as bucket,
    tm.supplier_type,
    count(distinct tm.property_code) as suppliers
  from trader_map as tm
  where confidence = 1
  group by bucket, supplier_type
  order by bucket, supplier_type;$$)
as ct(
  bucket text,
  "Direct suppliers" bigint,
  "Indirect suppliers" bigint);
  
select
  tm.supplier_type,
  avg(st_area(tm.geom::geography)) / 10000 as average_size
from trader_map as tm
where tm.confidence = 1
group by supplier_type;
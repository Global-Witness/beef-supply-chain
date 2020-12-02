drop table if exists trader_map;

create table trader_map(
  id            serial primary key,
  property_code varchar(100),
  estab_code    varchar(100),
  trader_name   varchar(100),
  supplier_type varchar(100),
  confidence    decimal,
  first_sale    timestamp,
  last_sale     timestamp,
  animals       int,
  geom          geometry);

with direct_suppliers as (
  select
    t.name as trader_name,
    s.state as state,
    'Direct' as supplier_type,
    s.producer_cpf_cnpj as cpf_cnpj,
    s.producer_estab_name as estab_name,
    s.producer_estab_code as estab_code,
    min(s.issue_date) as first_sale,
    max(s.issue_date) as last_sale,
    sum(s.animals) as animals
  from sales as s
  inner join traders as t on
    s.state = t.state and
    left(s.buyer_cpf_cnpj, 8) = t.base_cnpj and
    left(s.producer_cpf_cnpj, 8) <> t.base_cnpj
  where
    s.state = 'PA' and
    s.species = 'BOVINA' and
    s.status <> 'CANCELADA' and
    s.end_use in ('ABATE', 'EXPORTAÇÃO', 'QUARENTENA') and
    s.issue_date between '2017-01-01'::timestamp and '2019-12-31'::timestamp
  group by
    t.name,
    s.state,
    s.producer_cpf_cnpj,
    s.producer_estab_name,
    s.producer_estab_code),

indirect_suppliers as (
  select
    t.name as trader_name,
    s2.state as state,
    'Indirect' as supplier_type,
    s2.producer_cpf_cnpj as cpf_cnpj,
    s2.producer_estab_name as estab_name,
    s2.producer_estab_code as estab_code,
    min(s2.issue_date) as first_sale,
    max(s2.issue_date) as last_sale,
    sum(s2.animals) as animals
  from sales as s1
  inner join traders as t on
    left(s1.buyer_cpf_cnpj, 8) = t.base_cnpj and
    left(s1.producer_cpf_cnpj, 8) <> t.base_cnpj
  inner join sales as s2 on
    s1.producer_estab_code = s2.buyer_estab_code
  where
    s1.end_use in ('ABATE', 'EXPORTAÇÃO', 'QUARENTENA') and
    s2.end_use = 'ENGORDA' and
    s1.species = 'BOVINA' and
    s2.species = 'BOVINA' and
    s1.state = 'PA' and
    s2.state = 'PA' and
    s1.status <> 'CANCELADA' and
    s2.status <> 'CANCELADA' and
    s1.issue_date between '2017-01-01'::timestamp and '2019-12-31'::timestamp and
    s1.issue_date > s2.issue_date and
    s2.issue_date > s1.issue_date - interval '15 months'
  group by
    t.name,
    s2.state,
    s2.producer_cpf_cnpj,
    s2.producer_estab_name,
    s2.producer_estab_code)

insert into trader_map(
  property_code,
  estab_code,
  trader_name,
  supplier_type,
  confidence,
  first_sale,
  last_sale,
  animals,
  geom)
select
  f.property_code,
  p.estab_code,
  p.trader_name,
  p.supplier_type,
  similarity(
    regexp_replace(regexp_replace(upper(unaccent(p.estab_name)), '[^A-Za-z0-9]', '', 'g'), '^FAZENDA', 'FAZ'),
    regexp_replace(regexp_replace(upper(unaccent(f.estab_name)), '[^A-Za-z0-9]', '', 'g'), '^FAZENDA', 'FAZ'))
    as confidence,
  p.first_sale,
  p.last_sale,
  p.animals,
  f.geom
from (
  select * from direct_suppliers
  union all
  select * from indirect_suppliers) as p
left join owners as o on
  p.state = o.state and
  p.cpf_cnpj = o.cpf_cnpj and
  left(p.estab_code, 7) = substring(o.property_code, 4, 7)
left join farms as f on
  o.property_code = f.property_code;

create index trader_map_property_code_idx on trader_map(property_code);
create index trader_map_trader_name_idx on trader_map(trader_name);
create index trader_map_supplier_type_idx on trader_map(supplier_type);
create index trader_map_confidence_idx on trader_map(confidence);
create index trader_map_first_sale_idx on trader_map(first_sale);
create index trader_map_last_sale_idx on trader_map(last_sale);
create index trader_map_geom_idx on trader_map using gist(geom);

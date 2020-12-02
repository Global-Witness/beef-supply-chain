drop table if exists farms;
create table farms(
  id            serial primary key,
  state         text,
  property_code text,
  estab_name    text,
  creation_date date,
  update_date   date,
  geom          geometry);

insert into farms(
  state,
  property_code,
  estab_name,
  creation_date,
  update_date,
  geom)
select
  'PA',
  data->'properties'->>'property_code',
  data->'properties'->>'producer_estab_name',
  to_date(data->'properties'->>'creation_date', 'YYYY-MM-DD'),
  to_date(data->'properties'->>'update_date', 'YYYY-MM-DD'),
  st_setsrid(st_geomfromgeojson(data->>'geometry'), 4674)
from import.semas_car
where data->'properties'->>'type' = 'Property boundary';

create index farms_geom_idx on farms using gist(geom);
create index farms_property_code_idx on farms(property_code);

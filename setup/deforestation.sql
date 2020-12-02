drop table if exists deforestation;
create table deforestation(
  id         int primary key,
  image_date date,
  geom       geometry);

insert into deforestation(
  id,
  image_date,
  area,
  geom)
select
  id,
  to_date(image_date, 'YYYY-MM-DD'),
  cast(area_km as decimal),
  st_makevalid(wkb_geometry)
from import.inpe_prodes
where image_date is not null;

create index deforestation_image_date_idx on deforestation(image_date);
create index deforestation_geom_idx on deforestation using gist(geom);

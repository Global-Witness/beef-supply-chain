select
  results.*,
  round(results.area_ha * :football_pitch_size, :area_round_dp) as area_fp
from (
  select
    count(distinct intersections.property_code),
    round((st_area(st_union(intersections.geom)::geography) / 10000)::numeric, :area_round_dp) as area_ha
  from (
    select
      f.property_code,
      st_intersection(f.geom, d.geom) as geom
    from import.gw_cases as c
    inner join farms as f on
  	  c.property_code = f.property_code
    inner join deforestation as d on
      st_intersects(d.geom, f.geom) and
      st_area(st_intersection(f.geom, d.geom)) >= st_area(d.geom) * .1
    where
      d.image_date between :'deforestation_start' and :'deforestation_end'
    group by
      f.property_code,
      f.geom,
      d.geom
  ) as intersections
) as results;

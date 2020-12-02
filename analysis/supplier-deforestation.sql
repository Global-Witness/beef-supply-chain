select
  results.*,
  round(results.area_ha * :football_pitch_size, :area_round_dp) as area_fp
from (
  select
    case
      when intersections.trader_name is null then 'Total'
      else intersections.trader_name
    end,
    round(count(distinct intersections.property_code), -1) as count,
    round((st_area(st_union(intersections.geom)::geography) / 10000)::numeric, :area_round_dp) as area_ha
  from (
    select
      tm.trader_name,
      tm.property_code,
      st_intersection(tm.geom, d.geom) as geom
    from (
      select
        property_code,
        trader_name,
        last_sale,
        geom
      from trader_map
      where
        supplier_type in (:supplier_type) and
        confidence >= :min_name_match_confidence
    ) as tm
    inner join deforestation as d on
      st_intersects(d.geom, tm.geom) and
      d.image_date < tm.last_sale and
      st_area(st_intersection(tm.geom, d.geom)) >= st_area(d.geom) * .1
    where
      d.image_date between :'deforestation_start' and :'deforestation_end'
  ) as intersections
  group by rollup(intersections.trader_name)
  order by intersections.trader_name
) as results;

drop table if exists owners;
create table owners(
  id            serial primary key,
  state         text,
  property_code text,
  cpf_cnpj      text);

insert into owners(
  state,
  estab_name,
  cpf_cnpj)
select
  'PA',
  data->'properties'->>'producer_estab_name',
  data->'properties'->>'property_code',
  jsonb_array_elements_text(data->'properties'->'producer_cpf_cnpj')
from import.semas_car
where data->'properties'->>'type' = 'Property boundary';

create index owners_property_code_idx on owners(property_code);
create index owners_cpf_cnpj_idx on owners(cpf_cnpj);

drop table if exists sales;

create table sales(
  id                  serial primary key,
  state               text,
  gta_series          text,
  gta_number          int,
  issue_date          timestamp,
  status              text,
  producer_estab_code text,
  producer_estab_name text,
  producer_cpf_cnpj   text,
  producer_name       text,
  buyer_estab_code    text,
  buyer_estab_name    text,
  buyer_cpf_cnpj      text,
  buyer_name          text,
  species             text,
  end_use             text,
  animals             int,
  animal_details      jsonb);

insert into sales(
  state,
  gta_series,
  gta_number,
  issue_date,
  status,
  producer_estab_code,
  producer_estab_name,
  producer_cpf_cnpj,
  producer_name,
  buyer_estab_code,
  buyer_estab_name,
  buyer_cpf_cnpj,
  buyer_name,
  species,
  end_use,
  animals,
  animal_details)
select
  'PA',
  gta.data->>'dsSerie',
  cast(gta.data->>'nrGta' as int),
  to_timestamp(concat(gta.data->>'dataEmissao', ' ', gta.data->>'horaEmissao'), 'DD/MM/YYYY HH24:MI:SS'),
  gta.data->>'status',
  gta.data->>'codEstabProcedencia',
  gta.data->>'estabProcedencia',
  gta.data->>'cpfCnpjProcedencia',
  gta.data->>'nomeProcedencia',
  gta.data->>'codEstabDestino',
  gta.data->>'estabDestino',
  gta.data->>'cpfCnpjDestino',
  gta.data->>'nomeDestino',
  gta.data->>'especie',
  gta.data->>'finalidade',
  cast(gta.data->>'totalAnimais' as int),
  gta.data->'animais'
from (
  select jsonb_array_elements(data->'response'->'gta') as data
  from import.adepara_gta) as gta
where gta.data->>'nrGta' is not null;

create index sales_issue_date_idx on sales(issue_date);
create index sales_state_idx on sales(state);
create index sales_species_idx on sales(species);
create index sales_status_idx on sales(status);
create index sales_end_use_idx on sales(end_use);
create index sales_producer_cpf_cnpj_idx on sales(producer_cpf_cnpj);
create index sales_buyer_cpf_cnpj_idx on sales(buyer_cpf_cnpj);
create index sales_buyer_base_cpf_cnpj_idx on sales(left(buyer_cpf_cnpj, 8));
create index sales_producer_name_idx on sales(producer_name);
create index sales_buyer_name_idx on sales(buyer_name);
create index sales_producer_estab_name_idx on sales(producer_estab_name);
create index sales_buyer_estab_name_idx on sales(buyer_estab_name);
create index sales_producer_estab_code_idx on sales(producer_estab_code);
create index sales_buyer_estab_code_idx on sales(buyer_estab_code);
create index sales_animal_details_idx on sales(animal_details);

-- Delete duplicate Para GTAs
delete from sales as a
using (
  select
    min(ctid) as ctid,
    concat(state, gta_series, gta_number) as key
  from sales 
  group by key
  having count(*) > 1) as b
where concat(a.state, a.gta_series, a.gta_number) = b.key 
and a.ctid <> b.ctid;

drop table if exists traders;

create table traders(
  id            serial primary key,
  state         varchar(2),
  name          varchar(100),
  base_cnpj     varchar(8));

insert into traders(
  state,
  name,
  base_cnpj)
values(
  'PA',
  'JBS',
  '02916265');

insert into traders(
  state,
  name,
  base_cnpj)
values(
  'PA',
  'Marfrig',
  '03853896');

insert into traders(
  state,
  name,
  base_cnpj)
values(
  'PA',
  'Minerva',
  '67620377');

create index traders_base_cnpj_idx on traders(base_cnpj);

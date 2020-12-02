# Make environment variables available
include .env
export $(shell sed 's/=.*//' .env)

# Prepare database
prep:
	psql -c 'create schema if not exists import'
	psql < setup/extensions.sql

# Load data
adepara:
	psql -c 'create table if not exists import.adepara_gta(data jsonb)'
	sed 's/\\/\\\\/g' < data/adepara/${ADEPARA_FILE} | \
	  psql -c 'copy import.adepara_gta(data) from stdin'

semas:
	psql -c 'create table if not exists import.semas_car(data jsonb)'
	setup/car-to-geojson.sh < data/semas/${SEMAS_FILE} | \
	  sed 's/\\/\\\\/g' | \
	  psql -c 'copy import.semas_car(data) from stdin'

inpe:
	psql -c 'drop table if exists import.inpe_prodes'
	ogr2ogr -f PostgreSQL \
	  PG:"host=${PGHOST}" \
	  data/inpe/${INPE_FILE} \
	  -nlt PROMOTE_TO_MULTI \
      -nln import.inpe_prodes

gw:
	psql -c 'create table if not exists import.gw_cases(property_code text, trader_name text)'
	psql -c 'copy import.gw_cases(property_code, trader_name) from stdin csv header' < data/gw/cases.csv

# Create tables for day-to-day use
traders:
	psql -f setup/traders.sql

sales:
	psql -f setup/sales.sql

farms:
	psql -f setup/farms.sql

owners:
	psql -f setup/owners.sql

deforestation:
	psql -f setup/deforestation.sql

# Create table for trader-by-trader map and further analysis
trader-map:
	psql -f analysis/trader-map.sql

stats:
	# Pará report: key summary statistics using cutoff date ${DEFORESTATION_START}

	@echo ''
	## Estimated count of direct vs. indirect suppliers
	@echo ''
	@psql \
	  -v supplier_round_dp=${SUPPLIER_ROUND_DP} \
	  -P "footer=off" \
	  -f analysis/supplier-count.sql

	@echo ''
	## Count of direct suppliers with confirmed illegal deforestation since ${DEFORESTATION_START}, with area
	@echo ''
	@psql \
	  -v supplier_round_dp=${SUPPLIER_ROUND_DP} \
	  -v area_round_dp=${AREA_ROUND_DP} \
	  -v football_pitch_size=${FOOTBALL_PITCH_SIZE} \
	  -v deforestation_start=${DEFORESTATION_START} \
	  -v deforestation_end=${DEFORESTATION_END} \
	  -P "footer=off" \
	  -f analysis/supplier-deforestation-confirmed.sql

	@echo ''
	## Estimated count of direct suppliers with deforestation since ${DEFORESTATION_START}, with area
	@echo ''
	@psql \
	  -v supplier_type=\'Direct\' \
	  -v min_name_match_confidence=${MIN_NAME_MATCH_CONFIDENCE} \
	  -v supplier_round_dp=${SUPPLIER_ROUND_DP} \
	  -v area_round_dp=${AREA_ROUND_DP} \
	  -v football_pitch_size=${FOOTBALL_PITCH_SIZE} \
	  -v deforestation_start=${DEFORESTATION_START} \
	  -v deforestation_end=${DEFORESTATION_END} \
	  -P "footer=off" \
	  -f analysis/supplier-deforestation.sql

	@echo ''
	## Estimated count of indirect suppliers with deforestation since ${DEFORESTATION_START}, with area
	@echo ''
	@psql \
	  -v supplier_type=\'Indirect\' \
	  -v min_name_match_confidence=${MIN_NAME_MATCH_CONFIDENCE} \
	  -v supplier_round_dp=${SUPPLIER_ROUND_DP} \
	  -v area_round_dp=${AREA_ROUND_DP} \
	  -v football_pitch_size=${FOOTBALL_PITCH_SIZE} \
	  -v deforestation_start=${DEFORESTATION_START} \
	  -v deforestation_end=${DEFORESTATION_END} \
	  -P "footer=off" \
	  -f analysis/supplier-deforestation.sql

	@echo ''
	## Estimated count of all suppliers with deforestation since ${DEFORESTATION_START}, with area
	@echo ''
	@psql \
	  -v supplier_type=\'Direct\',\ \'Indirect\' \
	  -v min_name_match_confidence=${MIN_NAME_MATCH_CONFIDENCE} \
	  -v supplier_round_dp=${SUPPLIER_ROUND_DP} \
	  -v area_round_dp=${AREA_ROUND_DP} \
	  -v football_pitch_size=${FOOTBALL_PITCH_SIZE} \
	  -v deforestation_start=${DEFORESTATION_START} \
	  -v deforestation_end=${DEFORESTATION_END} \
	  -P "footer=off" \
	  -f analysis/supplier-deforestation.sql

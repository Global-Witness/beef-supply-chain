# Pará beef supply chain analysis

This repository contains tools and data to perform analysis on beef supply chains in the Brazilian state of Pará. The primary components: scrapers for Animal Transit Guide (GTA) and Rural Environmental Registry (CAR) documents from their respective state registries, implemented using the Scrapy framework; SQL statements and a jq script for importing the resulting data, along with deforestation data from the Brazilian space agency, into PostGIS; a set of SQL queries for analysing the data and producing maps and summary statistics used in Global Witness's 2020 report _Beef, Banks and the Brazilian Amazon_; and a makefile tying these all together. The resulting database was also used by Global Witness's forest investigations team, in combination with other sources, to conduct the analysis of potentially illegal deforestation and inspection of case studies in the report.

## Preliminaries

All code in this repository is provided under the MIT license. If you have questions or comments, feel free to file an issue or contact [Louis Goddard](mailto:lgoddard@globalwitness.org) ([@ltrgoddard](https://twitter.com/ltrgoddard)).

## Data

Title | Description | Source | Format | Location
------|-------------|--------|--------|---------
[Annual increments of deforestation in the legal Amazon](http://www.dpi.inpe.br/prodesdigital/dadosn/) | Geodata showing areas of deforestation over time, derived from satellite imagery | National Institute for Space Research (INPE) | Unzipped shapefile | `data/inpe`
[Animal Transit Guides (GTA)](https://siapec3.adepara.pa.gov.br/siapec3/portaldeservicos.wsp) | Certificates filed when animals are moved between farms and slaughterhouses, containing details of the sale, the seller and the buyer | Pará state agriculture agency (Adepará) | Newline-delimited JSON downloaded using scraper | `data/adepara`
[Rural Environmental Registry (CAR) filings](http://car.semas.pa.gov.br/#/consulta/mapa) | Geodata showing self-declared boundaries of rural properties, including ownership details | Pará state environment agency (SEMAS) | Newline-delimited GeoJSON downloaded using scraper | `data/semas`
Confirmed cases of illegal deforestation | A list of *números do recibo* for CARs manually flagged by Global Witness investigators—not provided with this repository, but can be replaced with an empty file or a list of your own | Global Witness | Plain text | `data/gw`

## Environment

To run the scripts in this repo, you'll need working installations of the following: PostgreSQL; PostGIS; Python 3; Scrapy; jq. Environment variables are set in `.env`, and are as follows:

* `PGHOST`, `PGDATABASE`, `PGUSER` and `PGPASS`—standard Postgres environment variables as described in the [Postgres documentation](https://www.postgresql.org/docs/current/libpq-envars.html)
* `INPE_FILE`, `ADEPARA_FILE`, `SEMAS_FILE` and `GW_FILE`—filenames (not full paths) for the data files located in their respective directories under `data`
* `MIN_NAME_MATCH_CONFIDENCE`, `AREA_ROUND_DP`, `SUPPLIER_ROUND_DP`, `FOOTBALL_PITCH_SIZE`, `DEFORESTATION_START` and `DEFORESTATION_END`—variables taken into account when producing summary statistics, described in more detail below.

## Scripts

### Scraping

The scrapers are provided as a shared Scrapy project under the `scrapers` directory, comprising two spiders. Both output newline-delimited JSON and should be run manually (i.e. separately to the makefile described below), either locally or via a hosted solution like Scrapinghub.

#### GTAs

Spider name: `gta`

Settings:

* `SERIES`—GTA series to target
* `START`—start of desired GTA number range
* `END`—end of desired GTA number range
* `ROTATING_PROXY_LIST`—list of proxy servers to use, each with the form 'username:password@ip-or-hostname:port'

Scraping is done by iterating through a known range of GTA series (E, Z, J, K, in that order) and numbers (0-999999). The scrape used by Global Witness encompasses GTAs from series E, number 636,503 (1 October 2015) to series K, number 135,199 (31 December 2019). Trial and error has shown that making more than one request every ~7.5 seconds from the same IP address causes the server to ban your IP temporarily. When this happens, the server issues a normal 200 response but with a message advising the requester that the operation isn't authorised and an internal code of 'MR0141'.

To avoid these bans, the scraper for the GTA data (`gta.py`) use a piece of custom middleware called [scrapy-rotating-proxies](https://github.com/TeamHG-Memex/scrapy-rotating-proxies). Before running it, make sure scrapy-rotating-proxies is installed (`pip install scrapy-rotating-proxies`) and update the list of proxy servers given in `beef_supply_chain_para/settings.py`. If you're deploying it to ScrapingHub, include `rotating_proxies` from the scrapy-rotating-proxies repo as a vendor directory at the same level as `beef_supply_chain_para` or specify it in your `requirements.txt`. The middleware will automatically rotate through a list of proxies given in the scraper's settings, and the policy in `beef_supply_chain_para/policy.py` bans the current proxy when Scrapy receives a response containing the code 'MR0141'.

Due to geo-IP restrictions implemented by Adepará, proxies used for scraping should all be located in Brazil—VPSs in AWS's sa-east-1 region work well.

#### CARs

Spider name: `car`

Settings:

* `START`—start of desired property ID range
* `END`—end of desired property ID range

The CAR scraper is simpler, as it relies on an open WFS server provided by SEMAS, the relevant agency in Pará. The main WFS endpoint can be found [here](http://car.semas.pa.gov.br/geoserver/secar-pa/wfs?service=wfs&version=2.0.0&request=GetFeature), with the relevant feature type being `secar-pa:area_imovel`. In an ideal world these features could be extracted directly using something like [ogr2ogr](https://gdal.org/programs/ogr2ogr.html), but testing has found this to be unreliable, likely due to the extreme complexity and size of some of the geometries.

To get around this, the scraper simply requests all features of the type `secar-pa:imovel` one by one by ID, using upper and lower bounds determined manually through trial and error. At the time of the scrape used by Global Witness (11 October 2019) these were 121,125 and 432,058. Running a new scrape using these numbers will not produce exactly the same results as in the report, due to the fact that CARs can be updated after submission.

### Loading and analysis

#### Makefile

The makefile included in this repo acts as a control panel for loading the data downloaded by the scrapers into the database, producing a set of more streamlined database tables for analysis, and producing the summary statistics. All steps are described with comments in the file itself and should be run in the order that they appear, through commands of the form `make prep`, `make adepara`, and so on.

#### Setup scripts

These scripts—located in `setup`—are used to prepare the database, ingest the relevant data (including transforming it where appropriate), and generate more usable, cut-down tables based on it. These are `traders` (a lookup table for the tax numbers of the three beef trading companies focussed on in the report), `sales` (based on the GTA data), `farms` and `owners` (based on the CAR data) and `deforestation` (based on INPE's deforestation data).

#### Analysis scripts

These scripts—located in `analysis`—are used to perform the actual analysis. This consists of generating a table called `trader_map`, which acts as the basis of a series of maps used in the report and serves as a single source of truth for subsequent summary statistics, then producing those summmary statistics based on the environment variables given in `.env`. These control the cutoff threshold to use when fuzzy-matching supplier names (`MIN_NAME_MATCH_CONFIDENCE`), number of decimal places to round to when giving areas of deforestation (`AREA_ROUND_DP`), the same but for counts of suppliers (`SUPPLIER_ROUND_DP`), the size of football pitch in hectares to use when generating summaries (`FOOTBALL_PITCH_SIZE`) and the earliest and latest dates of deforestation to consider (`DEFORESTATION_START` and `DEFORESTATION_END`). A detailed description of the methodology behind `trader_map` and the summary statistics is given below:

1. Select all GTAs meeting the following conditions—these will be considered direct suppliers:
   * `state` is 'PA';
   * `species` is 'BOVINA';
   * `status` isn't 'CANCELADA';
   * `end_use` is one of 'ABATE', 'EXPORTAÇÃO' and 'QUARENTENA' (types of use associated with final sale);
   * `issue_date` falls within the years 2017–19; and
   * the first eight characters of `buyer_cpf_cnpj` match the `base_cnpj` for at least one of the traders in the `traders` table.

2. Having selected the direct suppliers, select the first level of indirect suppliers using the following conditions:
   * `state` 'PA';
   * `species` is 'BOVINA';
   * `status` isn't 'CANCELADA';
   * `end_use` is 'ENGORDA' (a type of use associated with intermediate sale);
   * `buyer_estab_code` matches the `producer_estab_code` of at least one of the direct suppliers mentioned above; and
   * `issue_date` is not earlier than 15 months before the `issue_date` of the GTA from the matching direct supplier (to give time for fattening).

3. The next step is to match these two sets of suppiers to farm boundaries from CARs. With the two sets of suppliers selected, put them into a table and compare each one with all the CARs, adding relevant information from the CAR when they meet the following conditions:
   * the `state` of the GTA matches the `state` of the CAR;
   * the `producer_cpf_cnpj` of the GTA matches the `cpf_cnpj` of the owner; and
   * the first seven chracters of the GTA's `estab_code`, representing the municipality, match characters four to ten of the CAR's `property_code`.

   For matched GTA/CAR farms, add a column comparing the names of the farms using pg\_trgm's `similarity()` function, having first removed accents, converted the word 'FAZENDA' at the start of a name to 'FAZ', converted to upper case and removed all whitespace and punctuation.

4. You now have a conservative list of potential direct and indirect suppliers for the three beef trading companies over the period 2017–19, with varying degrees of confidennce based on the names matching between GTAs and CARs. This is used directly to produce the maps in the report, filtering using the `supplier_type` column in QGIS. To produce the summary statistics, the queries in `analysis`—particularly `supplier-deforestation.sql`—simply find the intersections between these farms and deforestation areas from the `deforestation` table and give the count and total area.

-- sql/01_load_staging.sql
-- Load the raw 2024 CMS Medicare Part D Geography-and-Drug CSV
-- into a persistent DuckDB staging table.
DROP TABLE IF EXISTS stg_partd_geo_drug;
CREATE TABLE stg_partd_geo_drug AS
SELECT *
FROM read_csv_auto(
        'C:/Users/Owner/Documents/partd-pgx-sql/Medicare Part D Prescribers - by Geography and Drug/Medicare Part D Prescribers - by Geography and Drug/2024/MUP_DPR_RY26_P04_V10_DY24_Geo.csv',
        sample_size = -1
    );
-- Confirm the persistent table has the same expected row count.
SELECT count(*) AS staged_row_count
FROM stg_partd_geo_drug;
-- Inspect the final inferred table schema.
DESCRIBE stg_partd_geo_drug;
-- Preview the staged data.
SELECT *
FROM stg_partd_geo_drug
LIMIT 5;

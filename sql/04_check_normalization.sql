-- sql/04_check_normalization.sql
-- Quality checks for v_partd_geo_drug_clean.

-- 1. Confirm the normalized view retains all source rows.
SELECT
    count(*) AS cleaned_row_count
FROM v_partd_geo_drug_clean;

-- 2. Confirm the normalized matching keys are populated.
SELECT
    count(*) AS total_rows,
    count(*) FILTER (
        WHERE generic_name_norm IS NULL
    ) AS null_normalized_generic_rows,
    count(*) FILTER (
        WHERE brand_name_norm IS NULL
    ) AS null_normalized_brand_rows
FROM v_partd_geo_drug_clean;

-- 3. Show examples of raw values and normalized matching keys.
SELECT
    Gnrc_Name,
    generic_name_norm,
    Brnd_Name,
    brand_name_norm
FROM v_partd_geo_drug_clean
ORDER BY
    Gnrc_Name,
    Brnd_Name
LIMIT 25;
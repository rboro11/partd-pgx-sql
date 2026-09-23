-- sql/02_profile_staging.sql
-- Profile the persistent CMS Geography-and-Drug staging table.
-- 1. Confirm the persistent table still has the expected number of rows.
SELECT count(*) AS staged_row_count
FROM stg_partd_geo_drug;
-- 2. Count rows by geographic aggregation level.
SELECT Prscrbr_Geo_Lvl,
    count(*) AS row_count
FROM stg_partd_geo_drug
GROUP BY Prscrbr_Geo_Lvl
ORDER BY row_count DESC;
-- 3. Inspect all geography-level values and a sample geography description.
SELECT DISTINCT Prscrbr_Geo_Lvl,
    Prscrbr_Geo_Cd,
    Prscrbr_Geo_Desc
FROM stg_partd_geo_drug
ORDER BY Prscrbr_Geo_Lvl,
    Prscrbr_Geo_Desc
LIMIT 100;
-- 4. Check whether generic or brand names are missing or blank.
SELECT count(*) AS total_rows,
    count(*) FILTER (
        WHERE Gnrc_Name IS NULL
            OR trim(Gnrc_Name) = ''
    ) AS null_or_blank_generic_name_rows,
    count(*) FILTER (
        WHERE Brnd_Name IS NULL
            OR trim(Brnd_Name) = ''
    ) AS null_or_blank_brand_name_rows
FROM stg_partd_geo_drug;
-- 5. Inspect raw generic and brand-name combinations.
SELECT DISTINCT Gnrc_Name,
    Brnd_Name
FROM stg_partd_geo_drug
WHERE Gnrc_Name IS NOT NULL
ORDER BY Gnrc_Name,
    Brnd_Name
LIMIT 100;
-- 6. Check numeric ranges and impossible negative values.
SELECT min(Tot_Clms) AS min_total_claims,
    max(Tot_Clms) AS max_total_claims,
    min(Tot_30day_Fills) AS min_total_30day_fills,
    max(Tot_30day_Fills) AS max_total_30day_fills,
    min(Tot_Drug_Cst) AS min_total_drug_cost,
    max(Tot_Drug_Cst) AS max_total_drug_cost,
    count(*) FILTER (
        WHERE Tot_Clms < 0
    ) AS negative_claim_rows,
    count(*) FILTER (
        WHERE Tot_30day_Fills < 0
    ) AS negative_fill_rows,
    count(*) FILTER (
        WHERE Tot_Drug_Cst < 0
    ) AS negative_cost_rows
FROM stg_partd_geo_drug;
-- 7. Display negative-value checks in a compact table.
SELECT count(*) FILTER (
        WHERE Tot_Clms < 0
    ) AS negative_claim_rows,
    count(*) FILTER (
        WHERE Tot_30day_Fills < 0
    ) AS negative_fill_rows,
    count(*) FILTER (
        WHERE Tot_Drug_Cst < 0
    ) AS negative_cost_rows
FROM stg_partd_geo_drug;
-- Initial profile findings:
-- - 117,661 total rows
-- - 114,029 State rows
-- - 3,632 National rows
-- - 0 null/blank generic names
-- - 0 null/blank brand names
-- - Minimum Tot_Clms = 11, consistent with CMS low-volume suppression
-- - 0 negative claims, fill, or cost values

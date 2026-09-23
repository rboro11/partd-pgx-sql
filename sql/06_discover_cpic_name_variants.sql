-- sql/06_discover_cpic_name_variants.sql
-- Discovery only: inspect CMS generic/brand strings containing
-- CPIC candidate drug tokens that did not have exact generic matches.
--
-- Do not use partial matching as final production logic.
-- Use results to build explicit crosswalk rows after manual review.

WITH candidate_terms AS (
    SELECT *
    FROM (
        VALUES
            ('abacavir'),
            ('amitriptyline'),
            ('citalopram'),
            ('clopidogrel'),
            ('codeine'),
            ('escitalopram'),
            ('irinotecan'),
            ('nortriptyline'),
            ('sertraline'),
            ('tramadol'),
            ('warfarin')
    ) AS t(candidate_drug)
),
matches AS (
    SELECT
        c.candidate_drug,
        d.Gnrc_Name,
        d.generic_name_norm,
        d.Brnd_Name,
        d.brand_name_norm,
        d.Prscrbr_Geo_Lvl,
        d.Tot_Clms,
        d.Tot_30day_Fills,
        d.Tot_Drug_Cst
    FROM candidate_terms c
    INNER JOIN v_partd_geo_drug_clean d
        ON d.generic_name_norm LIKE '%' || c.candidate_drug || '%'
        OR d.brand_name_norm LIKE '%' || c.candidate_drug || '%'
)
SELECT
    candidate_drug,
    Gnrc_Name,
    generic_name_norm,
    Brnd_Name,
    brand_name_norm,
    Prscrbr_Geo_Lvl,
    count(*) AS source_row_count,
    sum(Tot_Clms) AS published_claims,
    sum(Tot_30day_Fills) AS published_30day_fills,
    sum(Tot_Drug_Cst) AS published_drug_cost
FROM matches
WHERE Prscrbr_Geo_Lvl = 'National'
GROUP BY
    candidate_drug,
    Gnrc_Name,
    generic_name_norm,
    Brnd_Name,
    brand_name_norm,
    Prscrbr_Geo_Lvl
ORDER BY
    candidate_drug,
    published_claims DESC,
    generic_name_norm,
    brand_name_norm;

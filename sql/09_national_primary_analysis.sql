-- sql/09_national_primary_analysis.sql
-- National published Part D volume associated with the primary CPIC drug panel.

WITH all_national AS (
    SELECT
        sum(Tot_Clms) AS all_published_claims,
        sum(Tot_30day_Fills) AS all_published_30day_fills,
        sum(Tot_Drug_Cst) AS all_published_drug_cost
    FROM stg_partd_geo_drug
    WHERE Prscrbr_Geo_Lvl = 'National'
),
primary_cpic_national AS (
    SELECT
        sum(Tot_Clms) AS primary_cpic_published_claims,
        sum(Tot_30day_Fills) AS primary_cpic_published_30day_fills,
        sum(Tot_Drug_Cst) AS primary_cpic_published_drug_cost
    FROM v_partd_geo_drug_primary_cpic
    WHERE Prscrbr_Geo_Lvl = 'National'
)
SELECT
    primary_cpic_published_claims,
    all_published_claims,
    primary_cpic_published_claims / nullif(all_published_claims, 0)
        AS published_primary_cpic_claim_share,
    primary_cpic_published_30day_fills,
    all_published_30day_fills,
    primary_cpic_published_30day_fills / nullif(all_published_30day_fills, 0)
        AS published_primary_cpic_fill_share,
    primary_cpic_published_drug_cost,
    all_published_drug_cost,
    primary_cpic_published_drug_cost / nullif(all_published_drug_cost, 0)
        AS published_primary_cpic_cost_share
FROM primary_cpic_national
CROSS JOIN all_national;
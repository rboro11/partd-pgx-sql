-- sql/10_national_results_long.sql
-- Present national primary-panel results in a non-truncated long format.

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
),
metrics AS (
    SELECT
        primary_cpic_published_claims,
        all_published_claims,
        primary_cpic_published_claims
            / nullif(all_published_claims, 0)
            AS published_primary_cpic_claim_share,

        primary_cpic_published_30day_fills,
        all_published_30day_fills,
        primary_cpic_published_30day_fills
            / nullif(all_published_30day_fills, 0)
            AS published_primary_cpic_fill_share,

        primary_cpic_published_drug_cost,
        all_published_drug_cost,
        primary_cpic_published_drug_cost
            / nullif(all_published_drug_cost, 0)
            AS published_primary_cpic_cost_share
    FROM primary_cpic_national
    CROSS JOIN all_national
)
SELECT
    'published_claims' AS metric,
    primary_cpic_published_claims AS primary_panel_value,
    all_published_claims AS all_drugs_value,
    published_primary_cpic_claim_share AS share,
    100 * published_primary_cpic_claim_share AS share_percent
FROM metrics

UNION ALL

SELECT
    'published_30day_fills' AS metric,
    primary_cpic_published_30day_fills AS primary_panel_value,
    all_published_30day_fills AS all_drugs_value,
    published_primary_cpic_fill_share AS share,
    100 * published_primary_cpic_fill_share AS share_percent
FROM metrics

UNION ALL

SELECT
    'published_drug_cost' AS metric,
    primary_cpic_published_drug_cost AS primary_panel_value,
    all_published_drug_cost AS all_drugs_value,
    published_primary_cpic_cost_share AS share,
    100 * published_primary_cpic_cost_share AS share_percent
FROM metrics;


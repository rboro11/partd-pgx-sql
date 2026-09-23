-- sql/11_state_primary_analysis.sql
-- State-level published Part D exposure for the primary CPIC panel.

WITH all_state AS (
    SELECT
        Prscrbr_Geo_Cd AS state_code,
        Prscrbr_Geo_Desc AS state,
        sum(Tot_Clms) AS all_published_claims,
        sum(Tot_30day_Fills) AS all_published_30day_fills,
        sum(Tot_Drug_Cst) AS all_published_drug_cost
    FROM stg_partd_geo_drug
    WHERE Prscrbr_Geo_Lvl = 'State'
    GROUP BY
        Prscrbr_Geo_Cd,
        Prscrbr_Geo_Desc
),
primary_cpic_state AS (
    SELECT
        Prscrbr_Geo_Cd AS state_code,
        Prscrbr_Geo_Desc AS state,
        sum(Tot_Clms) AS primary_cpic_published_claims,
        sum(Tot_30day_Fills) AS primary_cpic_published_30day_fills,
        sum(Tot_Drug_Cst) AS primary_cpic_published_drug_cost,
        count(DISTINCT canonical_drug) AS visible_primary_cpic_drugs
    FROM v_partd_geo_drug_primary_cpic
    WHERE Prscrbr_Geo_Lvl = 'State'
    GROUP BY
        Prscrbr_Geo_Cd,
        Prscrbr_Geo_Desc
)
SELECT
    a.state_code,
    a.state,
    coalesce(c.primary_cpic_published_claims, 0)
        AS primary_cpic_published_claims,
    a.all_published_claims,
    coalesce(c.primary_cpic_published_claims, 0)
        / nullif(a.all_published_claims, 0)
        AS published_primary_cpic_claim_share,
    100 * coalesce(c.primary_cpic_published_claims, 0)
        / nullif(a.all_published_claims, 0)
        AS published_primary_cpic_claim_share_percent,
    coalesce(c.primary_cpic_published_30day_fills, 0)
        AS primary_cpic_published_30day_fills,
    a.all_published_30day_fills,
    coalesce(c.primary_cpic_published_30day_fills, 0)
        / nullif(a.all_published_30day_fills, 0)
        AS published_primary_cpic_fill_share,
    coalesce(c.primary_cpic_published_drug_cost, 0)
        AS primary_cpic_published_drug_cost,
    a.all_published_drug_cost,
    coalesce(c.primary_cpic_published_drug_cost, 0)
        / nullif(a.all_published_drug_cost, 0)
        AS published_primary_cpic_cost_share,
    coalesce(c.visible_primary_cpic_drugs, 0)
        AS visible_primary_cpic_drugs
FROM all_state a
LEFT JOIN primary_cpic_state c
    ON a.state_code = c.state_code
ORDER BY
    published_primary_cpic_claim_share DESC,
    a.state;
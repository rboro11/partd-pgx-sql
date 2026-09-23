-- sql/13_state_results_compact.sql
-- Compact state ranking for reporting and review.

WITH all_state AS (
    SELECT
        Prscrbr_Geo_Cd AS state_code,
        Prscrbr_Geo_Desc AS state,
        sum(Tot_Clms) AS all_published_claims
    FROM stg_partd_geo_drug
    WHERE Prscrbr_Geo_Lvl = 'State'
    GROUP BY
        Prscrbr_Geo_Cd,
        Prscrbr_Geo_Desc
),
primary_cpic_state AS (
    SELECT
        Prscrbr_Geo_Cd AS state_code,
        sum(Tot_Clms) AS primary_cpic_published_claims,
        count(DISTINCT canonical_drug) AS visible_primary_cpic_drugs
    FROM v_partd_geo_drug_primary_cpic
    WHERE Prscrbr_Geo_Lvl = 'State'
    GROUP BY
        Prscrbr_Geo_Cd
)
SELECT
    a.state_code,
    a.state,
    coalesce(c.primary_cpic_published_claims, 0)
        AS primary_cpic_published_claims,
    a.all_published_claims,
    round(
        100.0 * coalesce(c.primary_cpic_published_claims, 0)
            / nullif(a.all_published_claims, 0),
        3
    ) AS primary_cpic_claim_share_percent,
    coalesce(c.visible_primary_cpic_drugs, 0)
        AS visible_primary_cpic_drugs
FROM all_state a
LEFT JOIN primary_cpic_state c
    ON a.state_code = c.state_code
ORDER BY
    primary_cpic_claim_share_percent DESC,
    a.state;
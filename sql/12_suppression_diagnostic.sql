-- sql/12_suppression_diagnostic.sql
-- Compare published National rows to the sum of published State rows.
-- A positive gap can reflect state-level suppression and public-file aggregation differences.

WITH national AS (
    SELECT
        canonical_drug,
        sum(Tot_Clms) AS national_published_claims
    FROM v_partd_geo_drug_primary_cpic
    WHERE Prscrbr_Geo_Lvl = 'National'
    GROUP BY
        canonical_drug
),
state_sum AS (
    SELECT
        canonical_drug,
        sum(Tot_Clms) AS sum_state_published_claims
    FROM v_partd_geo_drug_primary_cpic
    WHERE Prscrbr_Geo_Lvl = 'State'
    GROUP BY
        canonical_drug
)
SELECT
    n.canonical_drug,
    n.national_published_claims,
    coalesce(s.sum_state_published_claims, 0)
        AS sum_state_published_claims,
    n.national_published_claims
        - coalesce(s.sum_state_published_claims, 0)
        AS national_minus_state_gap,
    100.0
        * (
            n.national_published_claims
            - coalesce(s.sum_state_published_claims, 0)
        )
        / nullif(n.national_published_claims, 0)
        AS national_minus_state_gap_percent
FROM national n
LEFT JOIN state_sum s
    ON n.canonical_drug = s.canonical_drug
ORDER BY
    national_minus_state_gap_percent DESC,
    n.canonical_drug;
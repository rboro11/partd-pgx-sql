-- sql/14_top_primary_drugs.sql
-- Rank primary CPIC-panel drugs by national published Part D claims.

SELECT
    canonical_drug,
    cpic_genes,
    sum(Tot_Clms) AS published_claims,
    sum(Tot_30day_Fills) AS published_30day_fills,
    sum(Tot_Drug_Cst) AS published_drug_cost,
    round(
        100.0 * sum(Tot_Clms)
            / sum(sum(Tot_Clms)) OVER (),
        2
    ) AS share_of_primary_panel_claims_percent
FROM v_partd_geo_drug_primary_cpic
WHERE Prscrbr_Geo_Lvl = 'National'
GROUP BY
    canonical_drug,
    cpic_genes
ORDER BY
    published_claims DESC;
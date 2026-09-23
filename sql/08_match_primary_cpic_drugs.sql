-- sql/08_match_primary_cpic_drugs.sql
-- Match CMS rows to the versioned primary CPIC drug panel.
-- Matching is exact against pre-reviewed normalized generic strings.

CREATE OR REPLACE VIEW v_partd_geo_drug_primary_cpic AS
SELECT
    d.*,
    x.canonical_drug,
    x.match_type,
    p.cpic_genes,
    p.analysis_group,
    p.expected_partd_presence,
    p.site_of_care_note,
    p.matching_scope
FROM v_partd_geo_drug_clean d
INNER JOIN ref_drug_name_crosswalk x
    ON d.generic_name_norm = x.cms_name_normalized
   AND x.cms_name_type = 'generic'
   AND x.active = true
INNER JOIN ref_cpic_drug_panel p
    ON x.canonical_drug = p.canonical_drug
   AND p.include_in_primary_panel = true;

-- Check primary matching coverage.
SELECT
    canonical_drug,
    cpic_genes,
    count(*) AS source_row_count,
    sum(Tot_Clms) AS published_claims,
    sum(Tot_30day_Fills) AS published_30day_fills,
    sum(Tot_Drug_Cst) AS published_drug_cost
FROM v_partd_geo_drug_primary_cpic
WHERE Prscrbr_Geo_Lvl = 'National'
GROUP BY
    canonical_drug,
    cpic_genes
ORDER BY
    published_claims DESC;

-- Verify every matched CMS row maps to exactly one canonical drug.
SELECT
    Prscrbr_Geo_Lvl,
    Prscrbr_Geo_Cd,
    Prscrbr_Geo_Desc,
    Gnrc_Name,
    Brnd_Name,
    count(DISTINCT canonical_drug) AS canonical_drug_count
FROM v_partd_geo_drug_primary_cpic
GROUP BY
    Prscrbr_Geo_Lvl,
    Prscrbr_Geo_Cd,
    Prscrbr_Geo_Desc,
    Gnrc_Name,
    Brnd_Name
HAVING count(DISTINCT canonical_drug) > 1;

-- Compact data-quality assertion: this must equal zero.
WITH duplicate_matches AS (
    SELECT
        Prscrbr_Geo_Lvl,
        Prscrbr_Geo_Cd,
        Prscrbr_Geo_Desc,
        Gnrc_Name,
        Brnd_Name,
        count(DISTINCT canonical_drug) AS canonical_drug_count
    FROM v_partd_geo_drug_primary_cpic
    GROUP BY
        Prscrbr_Geo_Lvl,
        Prscrbr_Geo_Cd,
        Prscrbr_Geo_Desc,
        Gnrc_Name,
        Brnd_Name
    HAVING count(DISTINCT canonical_drug) > 1
)
SELECT
    count(*) AS duplicate_source_row_count
FROM duplicate_matches;
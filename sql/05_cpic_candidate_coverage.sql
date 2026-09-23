-- sql/05_cpic_candidate_coverage.sql
-- Audit visible CMS coverage for the initial CPIC candidate drugs.

WITH candidate_drugs AS (
    SELECT *
    FROM (
        VALUES
            ('abacavir'),
            ('allopurinol'),
            ('amitriptyline'),
            ('azathioprine'),
            ('carbamazepine'),
            ('citalopram'),
            ('clopidogrel'),
            ('codeine'),
            ('escitalopram'),
            ('fluorouracil'),
            ('irinotecan'),
            ('mercaptopurine'),
            ('nortriptyline'),
            ('sertraline'),
            ('simvastatin'),
            ('tramadol'),
            ('warfarin')
    ) AS t(canonical_drug)
),
national AS (
    SELECT *
    FROM v_partd_geo_drug_clean
    WHERE Prscrbr_Geo_Lvl = 'National'
),
observed AS (
    SELECT
        generic_name_norm AS canonical_drug,
        count(*) AS national_source_rows,
        sum(Tot_Clms) AS national_published_claims,
        sum(Tot_30day_Fills) AS national_published_30day_fills,
        sum(Tot_Drug_Cst) AS national_published_drug_cost,
        count(DISTINCT brand_name_norm) AS observed_brand_name_count
    FROM national
    WHERE generic_name_norm IN (
        'abacavir',
        'allopurinol',
        'amitriptyline',
        'azathioprine',
        'carbamazepine',
        'citalopram',
        'clopidogrel',
        'codeine',
        'escitalopram',
        'fluorouracil',
        'irinotecan',
        'mercaptopurine',
        'nortriptyline',
        'sertraline',
        'simvastatin',
        'tramadol',
        'warfarin'
    )
    GROUP BY
        generic_name_norm
)
SELECT
    c.canonical_drug,
    coalesce(o.national_source_rows, 0) AS national_source_rows,
    coalesce(o.national_published_claims, 0) AS national_published_claims,
    coalesce(o.national_published_30day_fills, 0) AS national_published_30day_fills,
    coalesce(o.national_published_drug_cost, 0) AS national_published_drug_cost,
    coalesce(o.observed_brand_name_count, 0) AS observed_brand_name_count,
    CASE
        WHEN o.canonical_drug IS NULL THEN 'no_exact_generic_match'
        WHEN o.national_published_claims = 0 THEN 'visible_row_zero_claims_review'
        ELSE 'exact_generic_match'
    END AS coverage_status
FROM candidate_drugs c
LEFT JOIN observed o
    ON c.canonical_drug = o.canonical_drug
ORDER BY
    national_published_claims DESC,
    c.canonical_drug;
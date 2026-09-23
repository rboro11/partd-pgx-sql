-- sql/04_audit_cpic_candidates.sql
-- Inspect exact CMS generic/brand values for the initial CPIC candidate panel.

SELECT DISTINCT
    Gnrc_Name,
    generic_name_norm,
    Brnd_Name,
    brand_name_norm
FROM v_partd_geo_drug_clean
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
ORDER BY
    generic_name_norm,
    brand_name_norm;
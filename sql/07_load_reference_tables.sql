-- sql/07_load_reference_tables.sql
-- Load the version-controlled CPIC panel and CMS drug-name crosswalk.

DROP TABLE IF EXISTS ref_cpic_drug_panel;
DROP TABLE IF EXISTS ref_drug_name_crosswalk;

CREATE TABLE ref_cpic_drug_panel AS
SELECT *
FROM read_csv_auto(
    'data/reference/cpic_drug_panel.csv',
    header = true,
    sample_size = -1
);

CREATE TABLE ref_drug_name_crosswalk AS
SELECT *
FROM read_csv_auto(
    'data/reference/drug_name_crosswalk.csv',
    header = true,
    sample_size = -1
);

-- Data-quality checks for the reference files.
SELECT
    count(*) AS panel_drug_count,
    count(*) FILTER (WHERE include_in_primary_panel = true)
        AS primary_panel_drug_count
FROM ref_cpic_drug_panel;

SELECT
    count(*) AS crosswalk_row_count,
    count(DISTINCT canonical_drug) AS crosswalk_canonical_drug_count
FROM ref_drug_name_crosswalk
WHERE active = true;

SELECT
    canonical_drug,
    cms_name_type,
    cms_name_normalized,
    match_type
FROM ref_drug_name_crosswalk
WHERE active = true
ORDER BY
    canonical_drug;
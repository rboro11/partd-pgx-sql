-- sql/03_normalize_drug_names.sql
-- Create a reusable cleaned view. The raw staging table remains unchanged.

CREATE OR REPLACE VIEW v_partd_geo_drug_clean AS
SELECT
    *,
    lower(
        trim(
            regexp_replace(Gnrc_Name, '\s+', ' ', 'g')
        )
    ) AS generic_name_norm,
    lower(
        trim(
            regexp_replace(Brnd_Name, '\s+', ' ', 'g')
        )
    ) AS brand_name_norm,
    nullif(
        lower(
            trim(
                regexp_replace(Gnrc_Name, '\s+', ' ', 'g')
            )
        ),
        ''
    ) AS generic_name_norm_null,
    nullif(
        lower(
            trim(
                regexp_replace(Brnd_Name, '\s+', ' ', 'g')
            )
        ),
        ''
    ) AS brand_name_norm_null
FROM stg_partd_geo_drug;

-- Confirm the view returns the same number of rows as the staging table.
SELECT
    count(*) AS cleaned_row_count
FROM v_partd_geo_drug_clean;

-- Show raw versus normalized values for auditability.
SELECT
    Gnrc_Name,
    generic_name_norm,
    Brnd_Name,
    brand_name_norm
FROM v_partd_geo_drug_clean
LIMIT 25;
-- Confirm normalized keys are not null.
SELECT
    count(*) AS total_rows,
    count(*) FILTER (WHERE generic_name_norm IS NULL)
        AS null_normalized_generic_rows,
    count(*) FILTER (WHERE brand_name_norm IS NULL)
        AS null_normalized_brand_rows
FROM v_partd_geo_drug_clean;
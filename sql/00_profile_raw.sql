-- Profile the raw CMS Geography-and-Drug CSV before loading it into DuckDB.

-- Confirm DuckDB can read the file and count every data row.
SELECT
    count(*) AS raw_row_count
FROM read_csv_auto(
    'Medicare Part D Prescribers - by Geography and Drug\Medicare Part D Prescribers - by Geography and Drug\2024\MUP_DPR_RY26_P04_V10_DY24_Geo.csv',
    sample_size = -1
);


-- Inspect the source schema inferred by DuckDB.
DESCRIBE
SELECT *
FROM read_csv_auto(
    'Medicare Part D Prescribers - by Geography and Drug\Medicare Part D Prescribers - by Geography and Drug\2024\MUP_DPR_RY26_P04_V10_DY24_Geo.csv',
    sample_size = -1
);

-- Preview raw records before creating a staging table.
SELECT *
FROM read_csv_auto(
    'Medicare Part D Prescribers - by Geography and Drug\Medicare Part D Prescribers - by Geography and Drug\2024\MUP_DPR_RY26_P04_V10_DY24_Geo.csv',
    sample_size = -1
)
LIMIT 5;
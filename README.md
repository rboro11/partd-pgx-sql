# Medicare Part D Exposure to CPIC-Actionable Drugs

A reproducible DuckDB/SQL case study that links a clinically curated pharmacogenomics panel to the 2024 CMS Medicare Part D Prescribers by Geography and Drug public-use dataset.

## Research question

**How much published Medicare Part D prescribing volume is associated with a conservative, CPIC-guided pharmacogenomic drug panel, and how does the observed share vary by state?**

The project focuses on a public-data analogue of a healthcare-AI and medication-safety problem: converting clinically meaningful medication knowledge into transparent, testable data logic. It uses exact, reviewed generic-name and salt-form matching rather than uncontrolled text matching.

## Why this project

Clinical AI, payer operations, and medication decision support require more than model outputs or generic SQL. They require:

- Reliable drug identity resolution.
- Traceable clinical inclusion and exclusion rules.
- Explicit handling of data suppression and incomplete denominators.
- Reproducible transformations and quality checks.
- Clear separation of descriptive utilization from clinical recommendations.

This project was built as portfolio evidence for healthcare data analytics, clinical informatics, clinical AI evaluation/safety, and healthcare AI engineering roles.

## Data sources

### CMS Medicare Part D Prescribers by Geography and Drug

- Reporting year: 2024.
- Unit of observation: published aggregate geography-by-drug record.
- Core measures used: total prescribers, claims, 30-day fills, total drug cost, and beneficiaries.
- Geography levels used: National and State.
- Public data source: [CMS Medicare Part D Prescribers](https://data.cms.gov/provider-summary-by-type-of-service/medicare-part-d-prescribers).

The CMS public-use file excludes low-volume aggregate records with fewer than 11 claims. Therefore, all results are described as **published, non-suppressed Part D volume**, not complete underlying Medicare utilization.

### CPIC pharmacogenomics scope

The analysis uses a repository-versioned, analysis-specific CPIC-oriented drug panel. CPIC guidance is used to identify drug-gene contexts relevant to pharmacogenomic clinical decision support; this analysis does not estimate the number of patients who should receive testing or provide patient-specific clinical recommendations.

Relevant resources:

- [CPIC Guidelines](https://cpicpgx.org/guidelines/)
- [CPIC Gene-Drug Pairs](https://cpicpgx.org/pairs/)

## Analytic scope

### Primary panel

The primary analysis includes 14 drugs with reviewed, exact normalized CMS generic-name mappings:

| Drug | PGx gene(s) | CMS matching approach |
|---|---|---|
| Abacavir | HLA-B | Abacavir sulfate |
| Allopurinol | HLA-B | Exact generic |
| Amitriptyline | CYP2D6; CYP2C19 | Amitriptyline HCl |
| Azathioprine | TPMT; NUDT15 | Exact generic |
| Carbamazepine | HLA-B | Exact generic |
| Citalopram | CYP2C19 | Citalopram hydrobromide |
| Clopidogrel | CYP2C19 | Clopidogrel bisulfate |
| Escitalopram | CYP2C19 | Escitalopram oxalate |
| Mercaptopurine | TPMT; NUDT15 | Exact generic |
| Nortriptyline | CYP2D6 | Nortriptyline HCl |
| Sertraline | CYP2C19; CYP2B6 | Sertraline HCl |
| Simvastatin | SLCO1B1 | Exact generic |
| Tramadol | CYP2D6 | Tramadol HCl |
| Warfarin | CYP2C9; VKORC1; CYP4F2 | Warfarin sodium |

### Sensitivity-only drugs

The project intentionally does not include the following in the primary claim-share denominator:

- **Codeine:** much of observed Part D volume appears in combination products; combinations require their own clinical scope rule.
- **Fluorouracil:** observed Part D products include topical formulations, which should not be interpreted as systemic DPYD-related oncology exposure.
- **Irinotecan:** Part D visibility is not a reliable proxy for infused oncology use, which is commonly represented through medical-benefit pathways.

### Important matching rule

The production crosswalk uses exact normalized strings only. It does not use substring matching.

This is important because discovery queries found that a substring search for `citalopram` also matched `escitalopram`. Discovery logic is useful for finding candidate aliases; it must not become the final matching rule.

## Pipeline

```text
Raw CMS 2024 Geography-and-Drug CSV
    ↓
Raw profiling
    ↓
DuckDB staging table: stg_partd_geo_drug
    ↓
Normalized view: v_partd_geo_drug_clean
    ↓
Versioned CPIC panel and reviewed CMS name crosswalk
    ↓
Primary matched view: v_partd_geo_drug_primary_cpic
    ↓
National, state, and suppression-diagnostic analyses
```

## Repository structure

```text
partd-pgx-sql/
├── data/
│   └── reference/
│       ├── cpic_drug_panel.csv
│       └── drug_name_crosswalk.csv
├── outputs/                     # generated locally; generally gitignored
├── reports/
│   └── methodology.md
├── sql/
│   ├── 00_profile_raw.sql
│   ├── 01_load_staging.sql
│   ├── 02_profile_staging.sql
│   ├── 03_normalize_drug_names.sql
│   ├── 04_check_normalization.sql
│   ├── 04_audit_cpic_candidates.sql
│   ├── 05_cpic_candidate_coverage.sql
│   ├── 06_discover_cpic_name_variants.sql
│   ├── 07_load_reference_tables.sql
│   ├── 08_match_primary_cpic_drugs.sql
│   ├── 09_national_primary_analysis.sql
│   ├── 10_national_results_long.sql
│   ├── 11_state_primary_analysis.sql
│   ├── 12_suppression_diagnostic.sql
│   ├── 13_state_results_compact.sql
│   └── 14_top_primary_drugs.sql
├── tests/
├── partd_pgx.duckdb             # generated locally; gitignored
└── README.md
```

## Reproduce the analysis

### Prerequisites

- Windows PowerShell.
- DuckDB CLI executable at `C:\tools\duckdb\duckdb.exe`.
- CMS 2024 Geography-and-Drug CSV downloaded locally.

### Configure the raw CSV path

The current load script uses this local input path:

```text
C:/Users/Owner/Documents/partd-pgx-sql/Medicare Part D Prescribers - by Geography and Drug/Medicare Part D Prescribers - by Geography and Drug/2024/MUP_DPR_RY26_P04_V10_DY24_Geo.csv
```

For a portable public repository, update `sql/01_load_staging.sql` to point to your own downloaded CSV or place the source file under a gitignored `data/raw/` directory.

### Run scripts

From the project root in PowerShell:

```powershell
& "C:\tools\duckdb\duckdb.exe" .\partd_pgx.duckdb -f .\sql\01_load_staging.sql
& "C:\tools\duckdb\duckdb.exe" .\partd_pgx.duckdb -f .\sql\02_profile_staging.sql
& "C:\tools\duckdb\duckdb.exe" .\partd_pgx.duckdb -f .\sql\03_normalize_drug_names.sql
& "C:\tools\duckdb\duckdb.exe" .\partd_pgx.duckdb -f .\sql\07_load_reference_tables.sql
& "C:\tools\duckdb\duckdb.exe" .\partd_pgx.duckdb -f .\sql\08_match_primary_cpic_drugs.sql
& "C:\tools\duckdb\duckdb.exe" .\partd_pgx.duckdb -f .\sql\10_national_results_long.sql
& "C:\tools\duckdb\duckdb.exe" .\partd_pgx.duckdb -f .\sql\13_state_results_compact.sql
& "C:\tools\duckdb\duckdb.exe" .\partd_pgx.duckdb -f .\sql\12_suppression_diagnostic.sql
& "C:\tools\duckdb\duckdb.exe" .\partd_pgx.duckdb -f .\sql\14_top_primary_drugs.sql
```

## Key findings

### National published volume

For the conservative 14-drug primary panel, the analysis found:

- **98,919,162 published Part D claims**.
- **5.781% of published national Part D claims**.
- **6.268% of published national 30-day fills**.
- **0.394% of aggregate published Part D drug cost**.

The difference between the panel's utilization share and cost share is consistent with a panel dominated by high-volume outpatient therapies rather than the specialty/high-cost therapies that account for a substantial share of Part D cost.

### Major national volume drivers

The leading matched drugs by published national claim volume include sertraline, simvastatin, clopidogrel, tramadol, escitalopram, allopurinol, citalopram, and warfarin.

### State-level pattern

The project produces state-level published claim-share rankings. Early high-ranking state codes include North Dakota, South Dakota, Iowa, Minnesota, Wyoming, Kansas, Wisconsin, Nebraska, Vermont, Montana, Arkansas, New Hampshire, Maine, and Pennsylvania. These rankings are descriptive only and should not be interpreted as differences in PGx testing quality, clinical quality, or population need.

### Suppression diagnostic

For the 14 high-volume primary-panel drugs, national published claims closely matched the sum of published state claims. The largest national-minus-state gap was 33 claims for abacavir, or 0.202%; most drugs had discrepancies well below 0.05%.

This supports the stability of claim-weighted state rollups for this selected high-volume panel while preserving the CMS public-file suppression caveat.

## Limitations

- The CMS file represents published aggregate Part D records, not patient-level records or complete medication exposure.
- Cells with fewer than 11 claims are excluded from the public file; missing state/drug rows must not be interpreted as zero utilization.
- Part D does not represent all medication administration settings. Infused and medical-benefit oncology drugs are particularly poorly represented by a Part D-only view.
- Drug-name matching is curated for this specific analysis panel and is not a general-purpose medication terminology service.
- The analysis does not estimate PGx-test eligibility, variant prevalence, clinical benefit, avoided adverse events, or cost-effectiveness.
- The analysis is descriptive and does not provide clinical advice or patient-specific recommendations.

## Quality controls

The project includes checks for:

- Raw row-count agreement: 117,661 CMS rows loaded into DuckDB.
- State/National geography-level distribution: 114,029 State rows and 3,632 National rows.
- Missing generic/brand names: zero null or blank source values in this release.
- Negative claims, fills, and cost values: zero rows.
- Exact reviewed crosswalk mappings rather than production substring matching.
- One-to-one canonical drug mapping checks.
- National-versus-state suppression reconciliation by canonical drug.

The repository retains `outputs/cpic_name_variant_discovery.csv` as a discovery-only audit trail for reviewed salt, combination, and formulation variants; final results use exact mappings from the versioned crosswalk rather than substring matching.

## Next steps

- Export final result tables to versioned CSV files and build one national summary figure plus a state ranking figure.
- Add sensitivity analyses for codeine combination products, topical fluorouracil, and medical-benefit-sensitive irinotecan.
- Extend from Geography-and-Drug data to Provider-and-Drug data for prescriber-specialty analysis.
- Parameterize raw-data paths for a more portable public release.
- Add automated SQL regression tests and GitHub Actions.

## License

MIT License. See `LICENSE`.

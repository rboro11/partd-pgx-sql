# Methodology

## Study objective

This project estimates the share of **published, non-suppressed Medicare Part D utilization** associated with a conservative, pharmacogenomics-relevant drug panel derived from Clinical Pharmacogenetics Implementation Consortium (CPIC) drug-gene guidance.

Primary question:

> Among drug-level aggregate records published in the 2024 CMS Medicare Part D Prescribers by Geography and Drug file, what volume of claims, standardized 30-day fills, and total drug cost is associated with the project’s primary CPIC-oriented medication panel nationally and by state?

The project is descriptive. It does not estimate pharmacogenomic test eligibility, genotype prevalence, clinical benefit, avoided adverse events, clinical appropriateness, or patient-specific treatment recommendations.

## Data source

### CMS Medicare Part D Prescribers by Geography and Drug

- Reporting year: 2024.
- File used: `MUP_DPR_RY26_P04_V10_DY24_Geo.csv`.
- Source: CMS Medicare Part D Prescribers by Geography and Drug public-use data.
- Raw records loaded: 117,661.
- Geography rows: 114,029 State rows and 3,632 National rows.

Each record represents a public aggregate at the intersection of geography and drug identity. It is not an individual patient record, prescription event, or individual prescriber record.

### CMS disclosure control

The CMS public-use file omits aggregate records based on fewer than 11 total claims. Therefore:

- A missing geography-by-drug row does not mean the medication was not used.
- Public state-level sums need not perfectly recover national published values.
- Counts, denominators, and state ranks are described as published or observed non-suppressed values.
- The project does not impute suppressed values or allocate national-minus-state residuals across states.

## Outcome measures

Primary measures from the CMS file:

| CMS field | Interpretation in this analysis |
|---|---|
| `Tot_Clms` | Published Part D claims, including original prescriptions and refills |
| `Tot_30day_Fills` | Published standardized 30-day-fill volume |
| `Tot_Drug_Cst` | Aggregate published total drug cost |
| `Tot_Prscrbrs` | Aggregate prescriber count; retained but not used in primary results |
| `Tot_Benes` | Aggregate beneficiary count; retained but not used in primary results |

National and state results use the corresponding `Prscrbr_Geo_Lvl` values:

```sql
WHERE Prscrbr_Geo_Lvl = 'National'
```

and:

```sql
WHERE Prscrbr_Geo_Lvl = 'State'
```

## Data processing

### Raw staging

The raw CMS CSV is loaded into DuckDB as:

```text
stg_partd_geo_drug
```

The staging table preserves the source field names and values. It is intentionally not altered by later cleaning steps.

Initial quality checks found:

- 117,661 staging-table rows.
- Zero null or blank `Gnrc_Name` values.
- Zero null or blank `Brnd_Name` values.
- Minimum `Tot_Clms` = 11.
- Zero negative claim, 30-day-fill, or drug-cost values.

### Drug-name normalization

The view:

```text
v_partd_geo_drug_clean
```

adds normalized matching keys without modifying raw values:

```sql
lower(trim(regexp_replace(Gnrc_Name, '\s+', ' ', 'g')))
lower(trim(regexp_replace(Brnd_Name, '\s+', ' ', 'g')))
```

Normalization performs:

1. Whitespace collapse.
2. Leading/trailing whitespace removal.
3. Lower-casing.
4. Empty-string-to-NULL conversion.

Raw CMS name fields remain available for auditability.

## CPIC-oriented panel definition

The project uses an analysis-specific, repository-versioned panel in:

```text
data/reference/cpic_drug_panel.csv
```

It distinguishes primary-analysis drugs from sensitivity-only drugs.

### Primary 14-drug panel

The primary panel includes only drugs with a reviewed, explicit generic mapping and a reasonably interpretable Part D outpatient context:

| Canonical drug | CPIC-associated gene(s) | Production CMS mapping |
|---|---|---|
| Abacavir | HLA-B | `abacavir sulfate` |
| Allopurinol | HLA-B | `allopurinol` |
| Amitriptyline | CYP2D6; CYP2C19 | `amitriptyline hcl` |
| Azathioprine | TPMT; NUDT15 | `azathioprine` |
| Carbamazepine | HLA-B | `carbamazepine` |
| Citalopram | CYP2C19 | `citalopram hydrobromide` |
| Clopidogrel | CYP2C19 | `clopidogrel bisulfate` |
| Escitalopram | CYP2C19 | `escitalopram oxalate` |
| Mercaptopurine | TPMT; NUDT15 | `mercaptopurine` |
| Nortriptyline | CYP2D6 | `nortriptyline hcl` |
| Sertraline | CYP2C19; CYP2B6 | `sertraline hcl` |
| Simvastatin | SLCO1B1 | `simvastatin` |
| Tramadol | CYP2D6 | `tramadol hcl` |
| Warfarin | CYP2C9; VKORC1; CYP4F2 | `warfarin sodium` |

### Sensitivity-only drugs

The project excludes the following from the primary denominator and retains them for future, separately labeled analyses:

| Drug | Reason for exclusion from primary panel |
|---|---|
| Codeine | Much of visible Part D volume is in combination products; the project does not assume that every combination has identical PGx decision context |
| Fluorouracil | CMS Part D rows include topical products such as Efudex and Tolak; these cannot be treated as systemic DPYD-oncology exposure |
| Irinotecan | Part D data are not a reliable measure of medical-benefit/infused oncology exposure; liposomal formulation adds additional context |

## Matching method

### Discovery phase

Initial exact generic matching identified only a subset of candidate drugs because CMS generic names contain salt forms, combinations, and formulation descriptors.

A discovery query using `LIKE` identified candidate variants. This query was deliberately used only for manual review. It was not used in the final matching logic.

A critical example: substring matching for `citalopram` also returned `escitalopram`, demonstrating why substring matching is inappropriate for production medication identity assignment.

### Retained variant-discovery audit

The repository retains `outputs/cpic_name_variant_discovery.csv` as an auditable discovery artifact. It records National-level CMS drug-name strings returned by the exploratory candidate-variant query, including the raw and normalized generic/brand names, published claims, standardized 30-day fills, and total drug cost.

This file was used to identify potential salt forms, fixed combinations, and formulation-specific products for manual review. Examples include `clopidogrel bisulfate`, `warfarin sodium`, `escitalopram oxalate`, combination analgesics containing codeine or tramadol, and topical fluorouracil products.

The file is **not** a production crosswalk and is not used directly in national or state result calculations. In particular:

- Candidate discovery used substring matching to maximize recall for manual review.
- Substring matches can produce false positives; for example, searching for `citalopram` also retrieves `escitalopram`.
- Production matching uses only exact equality between `generic_name_norm` and a pre-reviewed entry in `data/reference/drug_name_crosswalk.csv`.
- Inclusion, exclusion, and sensitivity-analysis decisions are recorded in `data/reference/cpic_drug_panel.csv` and the reviewed crosswalk—not inferred automatically from the discovery file.

Retaining the discovery audit makes the medication-identity decision process inspectable while preserving a strict separation between exploratory search logic and the final analytical definition.

### Production crosswalk

The production crosswalk resides in:

```text
data/reference/drug_name_crosswalk.csv
```

Each row contains:

- `canonical_drug`
- `cms_name_type`
- `cms_name_normalized`
- `match_type`
- `source_or_rationale`
- `active`

Production matching uses exact equality between normalized generic CMS names and reviewed crosswalk strings:

```sql
ON d.generic_name_norm = x.cms_name_normalized
AND x.cms_name_type = 'generic'
AND x.active = true
```

No fuzzy matching, uncontrolled substring matching, or unreviewed brand-name matching is used in the primary analysis.

Combination products, route-ambiguous products, and formulation-specific products are excluded unless explicitly added through a documented sensitivity analysis.

## Primary analytic definitions

### National claim share

\[
\text{Published primary CPIC claim share} =
\frac{\sum \text{Tot\_Clms for matched primary-panel rows at National geography}}{\sum \text{Tot\_Clms for all National geography rows}}
\]

### National 30-day-fill share

\[
\text{Published primary CPIC fill share} =
\frac{\sum \text{Tot\_30day\_Fills for matched primary-panel rows at National geography}}{\sum \text{Tot\_30day\_Fills for all National geography rows}}
\]

### National cost share

\[
\text{Published primary CPIC cost share} =
\frac{\sum \text{Tot\_Drug\_Cst for matched primary-panel rows at National geography}}{\sum \text{Tot\_Drug\_Cst for all National geography rows}}
\]

### State claim share

For state \(s\):

\[
\text{Published primary CPIC claim share}_s =
\frac{\sum \text{matched primary-panel claims in }s}{\sum \text{all published claims in }s}
\]

The state analysis is descriptive. It does not assess state quality, prescribing quality, PGx test uptake, disease prevalence, or clinical appropriateness.

## National results

For the conservative primary panel:

| Metric | Result |
|---|---:|
| Published primary-panel claims | 98,919,162 |
| Published primary-panel claim share | 5.781% |
| Published primary-panel 30-day-fill share | 6.268% |
| Published primary-panel cost share | 0.394% |

The difference between claim/fill share and cost share is consistent with a panel dominated by high-volume outpatient therapies rather than a panel designed to capture specialty/high-cost drug spending.

## Suppression-reconciliation diagnostic

For each canonical primary-panel drug, the project calculates:

\[
\Delta_d = \text{National published claims}_d - \sum_s \text{State published claims}_{s,d}
\]

The national-minus-state gap is not allocated across states. It is reported only as a diagnostic for public-file suppression and aggregation differences.

Observed gaps for the 14 primary drugs were small:

- Largest relative gap: abacavir, 33 claims or 0.202% of national published claims.
- Most primary drugs had gaps below 0.05%.
- Several high-volume drugs had gaps below 0.001%.

This does not eliminate the disclosure-control limitation. It indicates that, for this selected high-volume panel, state-level published claim totals closely reconstruct national published totals.

## Reproducibility

Core SQL scripts are organized in sequential stages:

```text
00_profile_raw.sql
01_load_staging.sql
02_profile_staging.sql
03_normalize_drug_names.sql
04_check_normalization.sql
04_audit_cpic_candidates.sql
05_cpic_candidate_coverage.sql
06_discover_cpic_name_variants.sql
07_load_reference_tables.sql
08_match_primary_cpic_drugs.sql
09_national_primary_analysis.sql
10_national_results_long.sql
11_state_primary_analysis.sql
12_suppression_diagnostic.sql
13_state_results_compact.sql
14_top_primary_drugs.sql
```

All scripts are run against a local DuckDB database. The local raw CMS file and database file should be excluded from version control. The panel and crosswalk CSV files should be committed because they encode analytical decisions.

## Limitations and responsible use

- This is a claims-volume analysis, not a patient-level clinical study.
- CPIC guidance supports how to use available genetic results; the analysis does not determine whether testing should occur for any person.
- The project does not estimate actionable genotype frequency, therapy changes, adverse-event reduction, quality of care, or return on investment.
- Findings cannot be generalized to Part B, medical-benefit, inpatient, cash-pay, uninsured, or non-Medicare populations.
- Results for low-volume and route-sensitive drugs require additional clinical and data-source context.
- Public CMS data are subject to disclosure controls; published totals may understate underlying utilization in suppressed cells.

## Future extensions

1. Add separately reported combination-product sensitivity analyses for codeine and tramadol.
2. Add a route/formulation-specific fluorouracil analysis that distinguishes topical from systemic oncology exposure where feasible.
3. Add a medical-benefit-aware oncology sensitivity design for irinotecan.
4. Join the CPIC crosswalk to the CMS Provider-and-Drug file for specialty-level results.
5. Parameterize the raw-file location and add a data-download/checksum workflow.
6. Add SQL tests and continuous integration.

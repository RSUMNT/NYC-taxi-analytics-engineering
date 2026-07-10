
# NYC Taxi Analytics Engineering — Learning Journal

## Project Overview
- **Goal:** Build a Medallion Architecture (Bronze → Silver → Gold) ELT pipeline
- **Tech Stack:** dbt-core, DuckDB (local), Apache Iceberg (future), Python, Airflow (future)
- **Data:** NYC Yellow Taxi trips
- **Start Date:** June 29, 2024

---

## Phase 1: Environment Setup & First dbt Model

### What I Did
1. Set up pyenv + Python 3.11.9
2. Created virtual environment
3. Installed dbt-core 1.7.0 + dbt-duckdb 1.7.1
4. Initialized dbt project with DuckDB
5. Created first staging model: `stg_yellow_trips`

### Key Decisions & Why
- **DuckDB vs Athena:** Started with DuckDB locally for fast feedback loop. No AWS infrastructure overhead. Plan to migrate to Athena + S3 in Phase 3 when I have real data ingestion.
- **dbt 1.7.0 vs 1.8.0:** Chose 1.7.0 for compatibility with dbt-duckdb 1.7.1. Version mismatches were my biggest blocker yesterday.
- **Staging layer (stg_*):** Cleans raw data (type casting, filtering nulls) without business logic. Makes downstream models simpler.

### Challenges & Solutions
| Challenge | Root Cause | Solution |
|-----------|-----------|----------|
| Athena catalog errors | AWS Glue/Athena require IAM + workgroup setup | Pivoted to DuckDB for local development |
| protobuf version conflict | dbt 1.8.0 + protobuf mismatch | Downgraded to dbt 1.7.0, pinned protobuf 4.23.4 |
| dbt init errors | Profile name mismatch | Ensured profiles.yml and dbt_project.yml had matching names |

### What I Learned
1. **ELT vs ETL:** I Went with doing ELT (Extract-Load-Transform). Load raw data first, transform inside the warehouse/lake. More flexible than ETL.
2. **dbt Models = SQL + Config:** A dbt model is a .sql file with a config block. Config tells dbt HOW to materialize (view, table, incremental, ephemeral).
3. **Staging Models:** Remove junk, cast types, rename columns. Keep raw data untouched. Staging is the "kitchen prep" — makes downstream cooking easier.
4. **Materialization Types:**
   - **View:** Just a saved query. No storage. Fast, but re-runs every time. Good for staging.
   - **Table:** Physical data stored. Slower to build, fast to query. Good for marts.
   - **Incremental:** Only insert NEW rows. Efficient for large datasets.
   - **Ephemeral:** Temporary, only during dbt run. Like a CTE.

### Alternatives I Considered
| Tool | Why Not | Why dbt Instead |
|------|---------|-----------------|
| **Dataform** (Google Cloud) | Locked into BigQuery ecosystem | dbt is database-agnostic. Switch from DuckDB → Athena → Snowflake with 1 config change |
| **SQLMesh** | Newer, less mature | dbt has community, docs, jobs board. Safer bet for portfolio |
| **Hand-written Python + SQL** | Unmaintainable, no lineage | dbt gives us testing, documentation, lineage graphs automatically |

### Next Phase
- Build fact table (fct_daily_trips) aggregating trips by day
- Add dbt tests (not_null, unique, relationships)
- Understand dbt ref() and dependencies

------------------------------------------------------------------------------------------------------------------

PHASE 2

##Intermediate Model & Star Schema Fact Table

### What I Built
- `models/intermediate/int_trips_cleaned.sql` — A view that:
  - Casts all raw CSV columns to proper data types
  - Filters invalid trips (zero passengers, zero distance, zero fare)
  - Joins to `dim_vendor`, `dim_rate_code`, `dim_payment_type` to add surrogate keys
  - Calculates trip duration in minutes using `datediff()`
- `models/marts/fact_trips.sql` — A table that:
  - Contains only foreign keys (vendor_key, rate_code_key, payment_type_key) and measures (fare, distance, tip, etc.)
  - Materialized as a physical table for fast querying
- Updated `models/marts/fct_daily_trips.sql` to source from `fact_trips` instead of old `stg_yellow_trips`
  - Added `count(distinct vendor_key)` — now I can see how many vendors operated each day
 
    <img width="341" height="615" alt="Screenshot 2026-07-10 at 11 25 59 AM" src="https://github.com/user-attachments/assets/e4752fdb-a0a0-4f49-a5ca-10023b803044" />

<img width="1440" height="856" alt="Screenshot 2026-07-10 at 11 24 49 AM" src="https://github.com/user-attachments/assets/497151fb-4497-4506-b533-93ebe7ee4141" />

<img width="428" height="531" alt="Screenshot 2026-07-10 at 11 25 18 AM" src="https://github.com/user-attachments/assets/341d55bd-b6b4-4382-bed4-0c390916af62" />


### Why I Built It This Way
- **Intermediate model**: Acts as the single source of cleaned, enriched trip data. Multiple fact tables can reference it without repeating joins and casts (DRY principle).
- **Fact table (star schema)**: Separated descriptive data (dimensions) from numeric measures (facts). This makes queries fast, storage efficient, and enables historical tracking of dimension changes (coming next).
- **Materialized as table**: Fact tables are queried heavily; physical storage is faster than recomputing a view each time.

### Issues I Faced
1. **Empty files after `touch`**: Used `nano` to actually write SQL content. Learned that `touch` only creates an empty file.
2. **Git push rejected**: Remote had changes I didn't have locally. Fixed with `git pull --rebase` before pushing.
3. **Pandas `ModuleNotFoundError`**: Virtual environment wasn't activated. Fixed with `source .venv/bin/activate` and `pip install pandas pyarrow`.
4. **Script path issue**: Ran `download_sample.py` from `scripts/` folder; CSV tried to save to `scripts/seeds/` which doesn't exist. Fixed by running from project root.

### Key Concepts Learned
- **Star Schema**: Facts (measures + foreign keys) surrounded by dimensions (descriptive attributes). Industry standard for analytics warehouses.
- **Surrogate Keys**: Internal integer keys generated with `row_number()`. Insulate warehouse from source system changes and enable SCD Type 2.
- **Intermediate models**: A Silver layer between raw staging and Gold marts. Does cleaning, joining, and enrichment once.
- **`ref()` function**: Tells dbt about model dependencies, enables automatic ordering, and powers lineage graphs.

### dbt Commands Used
```bash
dbt seed --select yellow_trips_real  # Load new CSV
dbt run                               # Run all models
dbt run -s model_name                 # Run specific model
dbt show --select model_name          # Preview model output
dbt docs generate                     # Generate lineage docs
dbt docs serve                        # View docs in browser


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

dbt seed --select yellow_trips_real  # Load new CSV
dbt run                               # Run all models
dbt run -s model_name                 # Run specific model
dbt show --select model_name          # Preview model output
dbt docs generate                     # Generate lineage docs
dbt docs serve                        # View docs in browser


## Day 3 — July 11, 2024 (Completed July 16): SCD Type 2 with dbt Snapshots

### What I Built
- `snapshots/vendor_snapshot.sql` — A dbt snapshot that tracks historical changes to vendor names
- Simulated a vendor name change from "VeriFone Inc" to "VeriFone Holdings"
- Verified SCD Type 2 works: old name preserved with `dbt_valid_to`, new name added with `dbt_valid_to = NULL`

### Issues I Faced & Solutions

1. **Querying the wrong database file**
   - Was querying `dbt_project.duckdb` but profiles.yml pointed to `dev.duckdb`
   - Lesson: Always check `~/.dbt/profiles.yml` to find the actual database path

2. **Schema name required for snapshots**
   - Snapshot was created in `snapshots` schema (as configured by `target_schema`)
   - Must query `snapshots.vendor_snapshot` not just `vendor_snapshot`
   - Lesson: Snapshots don't go to the default `main` schema

3. **Invalid snapshot config key: `time_stamp`**
   - Originally had `time_stamp ='snapshots'` in config
   - Valid keys are: `target_schema`, `unique_key`, `strategy`, `updated_at`
   - Lesson: dbt silently ignores invalid config keys; snapshot still ran but incorrectly

4. **Multiple snapshot runs create duplicate versions**
   - Each `dbt snapshot` run with `current_timestamp` creates new rows
   - In production, use a real `updated_at` column from the source system
   - Lesson: For demos, reset the snapshot table between simulations

### Key Concepts Learned
- **SCD Type 2**: Tracks dimension changes by adding new rows (not overwriting)
- **dbt Snapshots**: Automate SCD Type 2 by comparing `updated_at` timestamps
- **`dbt_valid_from` / `dbt_valid_to`**: System columns dbt adds to track row validity periods
- **`unique_key`**: Must be the NATURAL key (vendor_id), not the surrogate key (vendor_key)

## Day 4 — July 12, 2024 (Completed July 16): dbt Tests, Schema Docs & Lineage

### What I Built
- `models/staging/schema.yml` — Tests and descriptions for all dimension tables
- `models/marts/schema.yml` — Tests for fact tables including foreign key relationships
- `tests/generic/positive_value.sql` — Custom test to ensure values are > 0
- Generated dbt documentation with `dbt docs generate` — full lineage graph

### Issues I Faced & Solutions

1. **Git push rejected (again)**
   - Remote had commits I didn't have locally
   - Fixed with: `git pull origin main --rebase` then `git push origin main`
   - Lesson: Always pull before pushing, especially after a break

2. **Understanding relationships test**
   - `relationships` test checks that foreign key values actually exist in the referenced dimension table
   - Syntax: `to: ref('dim_vendor')` and `field: vendor_key`
   - Lesson: This catches orphaned fact rows before they corrupt reports

3. **Custom tests use Jinja templates**
   - `{% test positive_value(model, column_name) %}` — dbt passes the model and column automatically
   - The test must return rows that FAIL the condition
   - Lesson: Custom tests are just SQL queries that return "bad" rows

### Key Concepts Learned
- **dbt tests**: Built-in (not_null, unique, relationships, accepted_values) + custom generic tests
- **schema.yml**: Single file that defines tests, descriptions, and column metadata
- **Relationships test**: Enforces referential integrity between facts and dimensions
- **dbt docs**: Auto-generates interactive documentation with lineage graphs
- **Lineage graph**: Shows data flow from seeds → staging → intermediate → marts

### dbt Commands Used

dbt test                    # Run all data quality tests

<img width="969" height="972" alt="Screenshot 2026-07-16 at 1 53 59 AM" src="https://github.com/user-attachments/assets/e72758b5-abe8-4645-83cf-ce142b7015fc" />


dbt docs generate           # Generate documentation

<img width="969" height="972" alt="Screenshot 2026-07-16 at 1 56 02 AM" src="https://github.com/user-attachments/assets/dcc723d1-254f-43e6-abef-398caed6df86" />


dbt docs serve              # View docs in browser at localhost:8080

Generated Lineage Graphs to relationships between tables. 

https://github.com/user-attachments/assets/1ae97339-0110-4d8b-8e48-f8e66e1b326a




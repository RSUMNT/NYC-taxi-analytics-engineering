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

---

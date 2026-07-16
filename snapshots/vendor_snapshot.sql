{% snapshot vendor_snapshot %}

{{ config(
target_schema = 'snapshots',
unique_key = 'vendor_id',
strategy = 'timestamp',
updated_at = 'dbt_updated_at'
)
}}

select vendor_id, vendor_name, current_timestamp as dbt_updated_at 
from {{ ref('dim_vendor') }}

{% endsnapshot %}



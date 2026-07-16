{{ config(materialized='table') }}

with source  as (
SELECT DISTINCT
store_and_fwd_flag AS store_and_fwd_id
from {{ ref('yellow_trips_real') }}
where store_and_fwd_id is NOT NULL)


SELECT row_number() over( order by store_and_fwd_id) as store_and_fwd_key,
store_and_fwd_id,
CASE 
WHEN store_and_fwd_id = 'Y' THEN 'Store and forward'
WHEN store_and_fwd_id = 'N' THEN ' Not Store and Forward'
ELSE 'Unknown'
END AS store_and_fwd_description
FROM source

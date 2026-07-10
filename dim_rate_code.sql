{{ config(materialized='table') }}

with rates as (
    select distinct RatecodeID as rate_code_id
    from {{ ref('yellow_trips_real') }}
    where RatecodeID is not null
)

select
    row_number() over (order by rate_code_id) as rate_code_key,
    rate_code_id,
    case
        when rate_code_id = 1 then 'Standard rate'
        when rate_code_id = 2 then 'JFK'
        when rate_code_id = 3 then 'Newark'
        when rate_code_id = 4 then 'Nassau or Westchester'
        when rate_code_id = 5 then 'Negotiated fare'
        when rate_code_id = 6 then 'Group ride'
        else 'Unknown'
    end as rate_code_description
from rates

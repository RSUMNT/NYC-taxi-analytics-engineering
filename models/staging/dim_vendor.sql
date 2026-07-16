{{ config(materialized='table') }}

with vendors as (
    select distinct VendorID as vendor_id
    from {{ ref('yellow_trips_real') }}
    where VendorID is not null
)

select
    row_number() over (order by vendor_id) as vendor_key,
    vendor_id,
    case
        when vendor_id = 1 then 'Creative Mobile Technologies'
        when vendor_id = 2 then 'VeriFone Holdings'
        else 'Unknown'
    end as vendor_name
from vendors

{{ config(materialized='view') }}

with base as (
    select
        cast(VendorID as integer) as vendor_id,
        cast(tpep_pickup_datetime as timestamp) as pickup_datetime,
        cast(tpep_dropoff_datetime as timestamp) as dropoff_datetime,
        cast(passenger_count as integer) as passenger_count,
        cast(trip_distance as double) as trip_distance,
        cast(RatecodeID as integer) as rate_code_id,
        cast(payment_type as integer) as payment_type_id,
        cast(fare_amount as double) as fare_amount,
        cast(extra as double) as extra,
        cast(mta_tax as double) as mta_tax,
        cast(tip_amount as double) as tip_amount,
        cast(tolls_amount as double) as tolls_amount,
        cast(improvement_surcharge as double) as improvement_surcharge,
        cast(total_amount as double) as total_amount,
        cast(congestion_surcharge as double) as congestion_surcharge
    from {{ ref('yellow_trips_real') }}
    where
        passenger_count > 0
        and trip_distance > 0
        and fare_amount > 0
)

select
    b.*,
    dv.vendor_key,
    dr.rate_code_key,
    dp.payment_type_key,
    datediff('minute', b.pickup_datetime, b.dropoff_datetime) as trip_duration_minutes
from base b
left join {{ ref('dim_vendor') }} dv on b.vendor_id = dv.vendor_id
left join {{ ref('dim_rate_code') }} dr on b.rate_code_id = dr.rate_code_id
left join {{ ref('dim_payment_type') }} dp on b.payment_type_id = dp.payment_type_id

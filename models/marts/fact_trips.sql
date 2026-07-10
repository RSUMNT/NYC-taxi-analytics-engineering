{{ config(materialized='table') }}

select
    vendor_key,
    rate_code_key,
    payment_type_key,
    date(pickup_datetime) as pickup_date,
    trip_distance,
    fare_amount,
    tip_amount,
    total_amount,
    passenger_count,
    trip_duration_minutes,
    pickup_datetime
from {{ ref('int_trips_cleaned') }}

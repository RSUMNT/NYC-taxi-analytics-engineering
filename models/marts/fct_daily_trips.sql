{{ config(materialized='table') }}

select
    pickup_date,
    count(*) as total_trips,
    sum(fare_amount) as total_revenue,
    avg(trip_distance) as avg_trip_distance,
    sum(passenger_count) as total_passengers,
    avg(fare_amount) as avg_fare,
    count(distinct vendor_key) as unique_vendors
from {{ ref('fact_trips') }}
group by pickup_date

{{ config(materialized='view') }}

with cleaned_data as (
select y.*,
CAST( y.pickup_datetime AS TIMESTAMP) AS pickup_datetime,
CAST( y.dropoff_datetime AS TIMESTAMP) AS dropoff_datetime,
CAST (y.passenger_count AS INTEGER) AS passenger_count
FROM yellow_trips_sample y
WHERE passenger_count > 0 AND passenger_count IS NOT NULL
)

select * from cleaned_data


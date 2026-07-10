{{ config(materialized='table') }}

with payments as (
    select distinct payment_type as payment_type_id
    from {{ ref('yellow_trips_real') }}
    where payment_type is not null
)

select
    row_number() over (order by payment_type_id) as payment_type_key,
    payment_type_id,
    case
        when payment_type_id = 1 then 'Credit card'
        when payment_type_id = 2 then 'Cash'
        when payment_type_id = 3 then 'No charge'
        when payment_type_id = 4 then 'Dispute'
        when payment_type_id = 5 then 'Unknown'
        when payment_type_id = 6 then 'Voided trip'
        else 'Other'
    end as payment_type_description
from payments

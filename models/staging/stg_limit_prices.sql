with source as (
    select * from {{ source('raw', 'limit_prices') }}
),

renamed as (
    select
        isin,
        minDate::date as min_date,
        maxDate::date as max_date,
        priceMinDate::decimal(20,4) as price_min_date,
        priceMaxDate::decimal(20,4) as price_max_date,
        profitability::decimal(20,4) as profitability
    from source
)

select * from renamed
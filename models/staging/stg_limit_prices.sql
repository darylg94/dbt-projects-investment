with source as (
    select * from {{ source('raw', 'limit_prices') }}
),

renamed as (
    select
        isin,
        timestamp::timestamp as price_date,
        upper_limit::decimal(20,4) as upper_limit_price,
        lower_limit::decimal(20,4) as lower_limit_price,
        currency
    from source
)

select * from renamed


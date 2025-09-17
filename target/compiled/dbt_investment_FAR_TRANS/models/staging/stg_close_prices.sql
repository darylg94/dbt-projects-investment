with source as (
    select * from FAR_TRANS_DB.raw.close_prices
),

renamed as (
    select
        isin,
        timestamp::timestamp as price_date,
        closeprice::decimal(20,4) as close_price
    from source
)

select * from renamed
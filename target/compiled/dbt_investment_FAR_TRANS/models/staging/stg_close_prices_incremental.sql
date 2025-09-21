

with source as (
    select * from FAR_TRANS_DB.raw.close_prices
    
    
        -- Only process new data since last run
        where timestamp > (select max(price_date) from FAR_TRANS_DB.staging.stg_close_prices_incremental)
    
),

renamed as (
    select
        isin,
        timestamp::timestamp as price_date,
        closeprice::decimal(20,4) as close_price,
        current_timestamp() as dbt_updated_at
    from source
)

select * from renamed
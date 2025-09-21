{{
  config(
    materialized='incremental',
    unique_key='isin || price_date',
    on_schema_change='fail',
    schema='staging'
  )
}}

with source as (
    select * from {{ source('raw', 'close_prices') }}
    
    {% if is_incremental() %}
        -- Only process new data since last run
        where timestamp > (select max(price_date) from {{ this }})
    {% endif %}
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

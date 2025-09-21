{{
  config(
    materialized='incremental',
    unique_key=['isin', 'price_date'],
    on_schema_change='sync_all_columns',
    schema='intermediate',
    incremental_strategy='merge'
  )
}}

with asset_info as (
    select * from {{ ref('stg_asset_information') }}
    where valid_to is null  -- Get current asset information
),

daily_prices as (
    select * from {{ ref('stg_close_prices') }}
    
    {% if is_incremental() %}
        -- Only process recent price data
        where price_date > (select max(price_date) from {{ this }})
    {% endif %}
),

daily_returns as (
    select
        isin,
        price_date,
        close_price,
        lag(close_price) over (partition by isin order by price_date) as prev_close_price,
        case 
            when lag(close_price) over (partition by isin order by price_date) > 0
            then (close_price - lag(close_price) over (partition by isin order by price_date)) / 
                 lag(close_price) over (partition by isin order by price_date)
            else null
        end as daily_return
    from daily_prices
),

final as (
    select
        dr.isin,
        dr.price_date,
        dr.close_price,
        dr.prev_close_price,
        dr.daily_return,
        ai.asset_name,
        ai.asset_category,
        ai.asset_sub_category,
        ai.sector,
        ai.industry,
        ai.market_id,
        current_timestamp() as dbt_updated_at
    from daily_returns dr
    left join asset_info ai on dr.isin = ai.isin
)

select * from final


  
    

        create or replace transient table FAR_TRANS_DB.MARTS.int_asset_daily_metrics_incremental
         as
        (

with asset_info as (
    select * from FAR_TRANS_DB.staging.stg_asset_information
    where valid_to is null  -- Get current asset information
),

daily_prices as (
    select * from FAR_TRANS_DB.staging.stg_close_prices
    
    
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
        );
      
  
{{
  config(
    materialized='incremental',
    unique_key='isin',
    on_schema_change='sync_all_columns',
    schema='marts',
    incremental_strategy='delete+insert',
    cluster_by=['asset_category', 'sector']
  )
}}

with daily_metrics as (
    select * from {{ ref('int_asset_daily_metrics_incremental') }}
    
    {% if is_incremental() %}
        -- Recalculate metrics for assets with new price data
        where isin in (
            select distinct isin 
            from {{ ref('int_asset_daily_metrics_incremental') }}
            where dbt_updated_at > (select max(last_updated) from {{ this }})
        )
    {% endif %}
),

asset_stats as (
    select
        isin,
        max(asset_name) as asset_name,
        max(asset_category) as asset_category,
        max(asset_sub_category) as asset_sub_category,
        max(sector) as sector,
        max(industry) as industry,
        max(market_id) as market_id,
        -- Date range
        min(price_date) as first_trading_date,
        max(price_date) as last_trading_date,
        count(*) as total_trading_days,
        -- Price statistics
        min(close_price) as min_price,
        max(close_price) as max_price,
        avg(close_price) as avg_price,
        stddev(close_price) as price_stddev,
        -- Return statistics
        avg(daily_return) as avg_daily_return,
        stddev(daily_return) as daily_volatility,
        min(daily_return) as min_daily_return,
        max(daily_return) as max_daily_return,
        -- Performance metrics
        (max(close_price) - min(close_price)) / nullif(min(close_price), 0) as total_return,
        count(case when daily_return > 0 then 1 end) as positive_days,
        count(case when daily_return < 0 then 1 end) as negative_days,
        count(case when daily_return = 0 then 1 end) as neutral_days
    from daily_metrics
    where daily_return is not null
    group by isin
),

final as (
    select
        *,
        -- Additional calculated metrics
        case 
            when total_trading_days > 0 
            then positive_days::float / total_trading_days 
            else null 
        end as win_rate,
        case 
            when daily_volatility > 0 
            then avg_daily_return / daily_volatility 
            else null 
        end as sharpe_ratio_daily,
        case 
            when asset_category = 'Stock' then 'Equity'
            when asset_category = 'Bond' then 'Fixed Income'
            when asset_category = 'MTF' then 'Fund'
            else 'Other'
        end as asset_class,
        case 
            when daily_volatility < 0.01 then 'Low'
            when daily_volatility < 0.02 then 'Medium'
            else 'High'
        end as volatility_category,
        current_timestamp() as last_updated
    from asset_stats
)

select * from final

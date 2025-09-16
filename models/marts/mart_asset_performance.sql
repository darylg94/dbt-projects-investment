with daily_metrics as (
    select * from {{ ref('int_asset_daily_metrics') }}
),

asset_stats as (
    select
        isin,
        asset_name,
        asset_category,
        asset_sub_category,
        sector,
        industry,
        min(price_date) as first_trading_date,
        max(price_date) as last_trading_date,
        min(close_price) as min_price,
        max(close_price) as max_price,
        avg(close_price) as avg_price,
        avg(daily_return) as avg_daily_return,
        stddev(daily_return) as daily_volatility,
        count(*) as trading_days
    from daily_metrics
    where daily_return is not null
    group by 1,2,3,4,5,6
)

select * from asset_stats


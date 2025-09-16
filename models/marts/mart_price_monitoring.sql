with daily_prices as (
    select * from {{ ref('stg_close_prices') }}
),

price_limits as (
    select * from {{ ref('stg_limit_prices') }}
),

market_hours as (
    select * from {{ ref('int_market_trading_hours') }}
),

price_analysis as (
    select
        dp.isin,
        dp.price_date,
        dp.close_price,
        pl.upper_limit_price,
        pl.lower_limit_price,
        pl.currency,
        mh.market_name,
        mh.country,
        mh.timezone,
        case
            when dp.close_price >= pl.upper_limit_price then 'Upper Limit Breach'
            when dp.close_price <= pl.lower_limit_price then 'Lower Limit Breach'
            else 'Within Limits'
        end as price_status,
        (dp.close_price - pl.lower_limit_price) / (pl.upper_limit_price - pl.lower_limit_price) * 100 as price_range_percentage
    from daily_prices dp
    left join price_limits pl on dp.isin = pl.isin and dp.price_date = pl.price_date
    left join market_hours mh on dp.isin = mh.isin
)

select * from price_analysis

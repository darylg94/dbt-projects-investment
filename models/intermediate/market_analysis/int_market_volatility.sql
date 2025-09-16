with daily_metrics as (
    select * from {{ ref('int_asset_daily_metrics') }}
),

market_info as (
    select * from {{ ref('stg_markets') }}
    where valid_to is null
),

rolling_volatility as (
    select
        dm.isin,
        dm.price_date,
        dm.asset_category,
        dm.sector,
        mi.market_id,
        mi.market_name,
        mi.timezone,
        avg(dm.daily_return) over (
            partition by dm.isin 
            order by dm.price_date 
            rows between {{ var('price_volatility_window') }} preceding and current row
        ) as rolling_avg_return,
        stddev(dm.daily_return) over (
            partition by dm.isin 
            order by dm.price_date 
            rows between {{ var('price_volatility_window') }} preceding and current row
        ) as rolling_volatility
    from daily_metrics dm
    left join market_info mi on dm.market_id = mi.market_id
)

select
    isin,
    price_date,
    asset_category,
    sector,
    market_id,
    market_name,
    timezone,
    rolling_avg_return,
    rolling_volatility,
    case
        when rolling_volatility > 0.02 then 'High'
        when rolling_volatility > 0.01 then 'Medium'
        else 'Low'
    end as volatility_category
from rolling_volatility

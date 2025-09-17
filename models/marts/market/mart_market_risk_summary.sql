with market_vol as (
    select * from {{ ref('int_market_volatility') }}
),

price_limits as (
    select * from {{ ref('stg_limit_prices') }}
),

market_risk_metrics as (
    select
        mv.market_id,
        mv.market_name,
        mv.price_date,
        count(distinct mv.isin) as total_assets,
        avg(mv.rolling_volatility) as avg_market_volatility,
        count(distinct case when mv.volatility_category = 'High' then mv.isin end) as high_volatility_assets,
        count(distinct case 
            when pl.close_price >= pl.upper_limit_price * {{ var('trading_limit_threshold') }}
            then mv.isin 
        end) as near_upper_limit_assets,
        count(distinct case 
            when pl.close_price <= pl.lower_limit_price / {{ var('trading_limit_threshold') }}
            then mv.isin 
        end) as near_lower_limit_assets
    from market_vol mv
    left join price_limits pl on mv.isin = pl.isin and mv.price_date = pl.price_date
    group by 1, 2, 3
)

select
    *,
    high_volatility_assets::float / nullif(total_assets, 0) as high_volatility_ratio,
    (near_upper_limit_assets + near_lower_limit_assets)::float / nullif(total_assets, 0) as price_limit_breach_ratio,
    case
        when high_volatility_ratio > 0.3 or price_limit_breach_ratio > 0.1 then 'High'
        when high_volatility_ratio > 0.15 or price_limit_breach_ratio > 0.05 then 'Medium'
        else 'Low'
    end as market_risk_level
from market_risk_metrics


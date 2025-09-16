with customer_risk as (
    select * from {{ ref('int_customer_risk_metrics') }}
),

market_conditions as (
    select * from {{ ref('mart_market_risk_summary') }}
    qualify row_number() over (partition by market_id order by price_date desc) = 1
),

asset_metrics as (
    select * from {{ ref('int_asset_daily_metrics') }}
    qualify row_number() over (partition by isin order by price_date desc) = 1
),

customer_recommendations as (
    select
        cr.customer_id,
        cr.risk_profile,
        cr.investment_capacity,
        cr.max_portfolio_volatility,
        cr.max_equity_allocation,
        am.isin,
        am.asset_name,
        am.asset_category,
        am.sector,
        mc.market_risk_level as current_market_risk,
        case
            when cr.risk_profile = 'Conservative' and mc.market_risk_level = 'Low' 
                and am.asset_category in ('Bond', 'Money Market') then 'Recommended'
            when cr.risk_profile = 'Moderate' and mc.market_risk_level != 'High'
                and am.rolling_volatility <= cr.max_portfolio_volatility then 'Recommended'
            when cr.risk_profile in ('Growth', 'Aggressive')
                and am.rolling_volatility <= cr.max_portfolio_volatility then 'Recommended'
            else 'Not Recommended'
        end as recommendation_status,
        current_timestamp() as recommendation_date
    from customer_risk cr
    cross join asset_metrics am
    left join market_conditions mc on am.market_id = mc.market_id
)

select * from customer_recommendations

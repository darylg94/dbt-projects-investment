with asset_info as (
    select * from {{ ref('stg_asset_information') }}
    where valid_to is null  -- Get current asset information
),

daily_prices as (
    select * from {{ ref('stg_close_prices') }}
),

daily_returns as (
    select
        isin,
        price_date,
        close_price,
        lag(close_price) over (partition by isin order by price_date) as prev_close_price,
        (close_price - lag(close_price) over (partition by isin order by price_date)) / 
        lag(close_price) over (partition by isin order by price_date) as daily_return
    from daily_prices
)

select
    dr.*,
    ai.asset_name,
    ai.asset_category,
    ai.asset_sub_category,
    ai.sector,
    ai.industry
from daily_returns dr
left join asset_info ai on dr.isin = ai.isin

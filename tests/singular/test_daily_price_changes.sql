-- Test to ensure daily price changes are within reasonable bounds
with daily_changes as (
    select
        isin,
        price_date,
        close_price,
        lag(close_price) over (partition by isin order by price_date) as prev_close,
        abs((close_price - lag(close_price) over (partition by isin order by price_date)) / 
            lag(close_price) over (partition by isin order by price_date)) as price_change_pct
    from {{ ref('stg_close_prices') }}
)

select *
from daily_changes
where price_change_pct > 0.5  -- Flag price changes greater than 50%
  and prev_close is not null

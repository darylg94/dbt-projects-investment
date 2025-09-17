select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      -- Test to ensure daily price changes are within reasonable bounds
with daily_changes as (
    select
        isin,
        price_date,
        close_price,
        lag(close_price) over (partition by isin order by price_date) as prev_close,
        abs((close_price - lag(close_price) over (partition by isin order by price_date)) / 
            lag(close_price) over (partition by isin order by price_date)) as price_change_pct
    from FAR_TRANS_DB.RAW.stg_close_prices
)

select *
from daily_changes
where price_change_pct > 0.5  -- Flag price changes greater than 50%
  and prev_close is not null
      
    ) dbt_internal_test
select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      

with validation as (
    select
        closeprice as close_price
    from FAR_TRANS_DB.raw.close_prices
    where closeprice <= 0
)

select *
from validation


      
    ) dbt_internal_test
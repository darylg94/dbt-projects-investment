select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      

with validation as (
    select
        close_price as close_price
    from FAR_TRANS_DB.RAW.stg_close_prices
    where close_price <= 0
)

select *
from validation


      
    ) dbt_internal_test
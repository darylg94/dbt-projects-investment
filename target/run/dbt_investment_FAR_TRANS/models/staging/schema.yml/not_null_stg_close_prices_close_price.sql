select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select close_price
from FAR_TRANS_DB.RAW.stg_close_prices
where close_price is null



      
    ) dbt_internal_test
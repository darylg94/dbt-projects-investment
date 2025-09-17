select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select closeprice
from FAR_TRANS_DB.raw.close_prices
where closeprice is null



      
    ) dbt_internal_test
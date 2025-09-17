select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select totalvalue
from FAR_TRANS_DB.raw.transactions
where totalvalue is null



      
    ) dbt_internal_test
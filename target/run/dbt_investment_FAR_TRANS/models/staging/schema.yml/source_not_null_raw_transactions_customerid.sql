select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select customerid
from FAR_TRANS_DB.raw.transactions
where customerid is null



      
    ) dbt_internal_test
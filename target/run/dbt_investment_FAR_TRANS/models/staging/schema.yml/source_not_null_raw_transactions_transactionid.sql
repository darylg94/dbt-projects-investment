select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select transactionid
from FAR_TRANS_DB.raw.transactions
where transactionid is null



      
    ) dbt_internal_test
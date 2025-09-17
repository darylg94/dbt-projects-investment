select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select transactiontype
from FAR_TRANS_DB.raw.transactions
where transactiontype is null



      
    ) dbt_internal_test
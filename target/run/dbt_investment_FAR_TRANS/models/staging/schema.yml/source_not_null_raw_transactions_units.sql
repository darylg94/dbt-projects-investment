select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select units
from FAR_TRANS_DB.raw.transactions
where units is null



      
    ) dbt_internal_test
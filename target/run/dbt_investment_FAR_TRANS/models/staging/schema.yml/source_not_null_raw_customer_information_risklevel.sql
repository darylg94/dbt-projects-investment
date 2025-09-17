select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select risklevel
from FAR_TRANS_DB.raw.customer_information
where risklevel is null



      
    ) dbt_internal_test
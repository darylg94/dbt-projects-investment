select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select customertype
from FAR_TRANS_DB.raw.customer_information
where customertype is null



      
    ) dbt_internal_test
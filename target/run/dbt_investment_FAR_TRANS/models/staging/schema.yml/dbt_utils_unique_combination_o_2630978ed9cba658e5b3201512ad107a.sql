select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      





with validation_errors as (

    select
        customer_id, valid_from
    from FAR_TRANS_DB.RAW.stg_customer_information
    group by customer_id, valid_from
    having count(*) > 1

)

select *
from validation_errors



      
    ) dbt_internal_test
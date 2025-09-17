select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    

with all_values as (

    select
        customertype as value_field,
        count(*) as n_records

    from FAR_TRANS_DB.raw.customer_information
    group by customertype

)

select *
from all_values
where value_field not in (
    'Premium','Mass'
)



      
    ) dbt_internal_test
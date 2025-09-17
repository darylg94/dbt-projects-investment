select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    

with all_values as (

    select
        investmentcapacity as value_field,
        count(*) as n_records

    from FAR_TRANS_DB.raw.customer_information
    group by investmentcapacity

)

select *
from all_values
where value_field not in (
    'Predicted_CAP_LT30K','CAP_30K_80K','CAP_80K_300K','CAP_300K_1M','CAP_GT1M'
)



      
    ) dbt_internal_test
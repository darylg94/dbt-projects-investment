select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    

with all_values as (

    select
        transactiontype as value_field,
        count(*) as n_records

    from FAR_TRANS_DB.raw.transactions
    group by transactiontype

)

select *
from all_values
where value_field not in (
    'Buy','Sell'
)



      
    ) dbt_internal_test
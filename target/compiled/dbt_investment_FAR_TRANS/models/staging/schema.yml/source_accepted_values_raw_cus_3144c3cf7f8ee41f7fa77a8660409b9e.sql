
    
    

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



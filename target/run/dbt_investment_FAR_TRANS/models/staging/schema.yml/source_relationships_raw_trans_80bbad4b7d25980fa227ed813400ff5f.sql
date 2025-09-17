select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    

with child as (
    select customerid as from_field
    from FAR_TRANS_DB.raw.transactions
    where customerid is not null
),

parent as (
    select customerid as to_field
    from FAR_TRANS_DB.raw.customer_information
)

select
    from_field

from child
left join parent
    on child.from_field = parent.to_field

where parent.to_field is null



      
    ) dbt_internal_test
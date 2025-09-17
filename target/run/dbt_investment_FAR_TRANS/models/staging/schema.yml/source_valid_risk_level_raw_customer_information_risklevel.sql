select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      

with validation as (
    select
        risklevel as risk_level
    from FAR_TRANS_DB.raw.customer_information
    where risklevel not in ('Income', 'Balanced', 'Growth', 'Aggressive')
)

select *
from validation


      
    ) dbt_internal_test
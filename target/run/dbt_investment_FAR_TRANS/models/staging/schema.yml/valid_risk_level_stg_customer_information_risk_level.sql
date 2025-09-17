select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      

with validation as (
    select
        risk_level as risk_level
    from FAR_TRANS_DB.RAW.stg_customer_information
    where risk_level not in ('Income', 'Balanced', 'Growth', 'Aggressive')
)

select *
from validation


      
    ) dbt_internal_test
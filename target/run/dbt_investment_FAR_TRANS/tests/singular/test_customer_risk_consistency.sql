select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      -- Test to ensure customer risk levels are consistent with investment capacity
with risk_validation as (
    select
        customer_id,
        risk_level,
        investment_capacity,
        case
            when risk_level = 'Aggressive' and investment_capacity = 'Predicted_CAP_LT30K' then 'Invalid'
            when risk_level = 'Income' and investment_capacity in ('CAP_300K_1M', 'CAP_GT1M') then 'Invalid'
            else 'Valid'
        end as consistency_check
    from FAR_TRANS_DB.RAW.stg_customer_information
    where valid_to is null  -- Check only current records
)

select *
from risk_validation
where consistency_check = 'Invalid'
      
    ) dbt_internal_test
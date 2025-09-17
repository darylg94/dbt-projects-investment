

with validation as (
    select
        risk_level as risk_level
    from FAR_TRANS_DB.RAW.stg_customer_information
    where risk_level not in ('Income', 'Balanced', 'Growth', 'Aggressive')
)

select *
from validation


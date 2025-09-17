

with validation as (
    select
        risklevel as risk_level
    from FAR_TRANS_DB.raw.customer_information
    where risklevel not in ('Income', 'Balanced', 'Growth', 'Aggressive')
)

select *
from validation


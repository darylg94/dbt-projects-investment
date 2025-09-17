





with validation_errors as (

    select
        customer_id, valid_from
    from FAR_TRANS_DB.RAW.stg_customer_information
    group by customer_id, valid_from
    having count(*) > 1

)

select *
from validation_errors



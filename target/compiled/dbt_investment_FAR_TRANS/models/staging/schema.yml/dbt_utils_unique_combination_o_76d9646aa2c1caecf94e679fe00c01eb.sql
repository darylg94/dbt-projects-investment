





with validation_errors as (

    select
        isin, price_date
    from FAR_TRANS_DB.staging.stg_close_prices
    group by isin, price_date
    having count(*) > 1

)

select *
from validation_errors



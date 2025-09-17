

with validation as (
    select
        closeprice as close_price
    from FAR_TRANS_DB.raw.close_prices
    where closeprice <= 0
)

select *
from validation


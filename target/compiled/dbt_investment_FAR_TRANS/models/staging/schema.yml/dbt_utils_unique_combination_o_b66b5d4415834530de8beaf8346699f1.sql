





with validation_errors as (

    select
        isin, valid_from
    from FAR_TRANS_DB.RAW.stg_asset_information
    group by isin, valid_from
    having count(*) > 1

)

select *
from validation_errors



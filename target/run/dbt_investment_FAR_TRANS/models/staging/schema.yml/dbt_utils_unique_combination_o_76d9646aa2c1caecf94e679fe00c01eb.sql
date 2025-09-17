select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      





with validation_errors as (

    select
        isin, price_date
    from FAR_TRANS_DB.RAW.stg_close_prices
    group by isin, price_date
    having count(*) > 1

)

select *
from validation_errors



      
    ) dbt_internal_test
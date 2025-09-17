select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select isin
from FAR_TRANS_DB.RAW.stg_asset_information
where isin is null



      
    ) dbt_internal_test
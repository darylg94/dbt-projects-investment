select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select assetcategory
from FAR_TRANS_DB.raw.asset_information
where assetcategory is null



      
    ) dbt_internal_test
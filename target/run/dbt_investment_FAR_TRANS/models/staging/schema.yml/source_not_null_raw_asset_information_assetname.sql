select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select assetname
from FAR_TRANS_DB.raw.asset_information
where assetname is null



      
    ) dbt_internal_test
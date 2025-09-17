select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    

select
    isin as unique_field,
    count(*) as n_records

from FAR_TRANS_DB.RAW.stg_asset_information
where isin is not null
group by isin
having count(*) > 1



      
    ) dbt_internal_test
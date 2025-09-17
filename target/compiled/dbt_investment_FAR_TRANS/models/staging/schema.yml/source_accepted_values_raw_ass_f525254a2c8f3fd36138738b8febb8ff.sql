
    
    

with all_values as (

    select
        assetcategory as value_field,
        count(*) as n_records

    from FAR_TRANS_DB.raw.asset_information
    group by assetcategory

)

select *
from all_values
where value_field not in (
    'Stock','Bond','MTF'
)




    
    

select
    isin as unique_field,
    count(*) as n_records

from FAR_TRANS_DB.RAW.stg_asset_information
where isin is not null
group by isin
having count(*) > 1



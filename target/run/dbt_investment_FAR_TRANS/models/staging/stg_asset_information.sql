
  create or replace   view FAR_TRANS_DB.RAW.stg_asset_information
  
   as (
    with source as (
    select * from FAR_TRANS_DB.raw.asset_information
),

renamed as (
    select
        isin,
        assetname as asset_name,
        assetshortname as asset_short_name,
        assetcategory as asset_category,
        assetsubcategory as asset_sub_category,
        marketid as market_id,
        sector,
        industry,
        timestamp::timestamp as valid_from,
        lead(timestamp::timestamp) over (partition by isin order by timestamp) as valid_to
    from source
)

select * from renamed
  );


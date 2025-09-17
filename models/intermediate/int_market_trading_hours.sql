with market_info as (
    select * from {{ ref('stg_markets') }}
    where valid_to is null  -- Get current market information
),

asset_markets as (
    select * from {{ ref('stg_asset_information') }}
    where valid_to is null  -- Get current asset information
)

select
    am.isin,
    am.asset_name,
    am.asset_category,
    mi.market_id,
    mi.market_name,
    mi.country,
    mi.timezone,
    mi.opening_time,
    mi.closing_time,
    mi.base_currency,
    mi.is_active
from asset_markets am
left join market_info mi on am.market_id = mi.market_id


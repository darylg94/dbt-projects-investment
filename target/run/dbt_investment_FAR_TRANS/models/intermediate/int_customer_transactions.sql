
  create or replace   view FAR_TRANS_DB.RAW.int_customer_transactions
  
   as (
    with customer_info as (
    select * from FAR_TRANS_DB.RAW.stg_customer_information
    where valid_to is null  -- Get current customer information
),

transactions as (
    select * from FAR_TRANS_DB.RAW.stg_transactions
),

asset_info as (
    select * from FAR_TRANS_DB.RAW.stg_asset_information
    where valid_to is null  -- Get current asset information
)

select
    t.transaction_id,
    t.customer_id,
    t.isin,
    t.transaction_type,
    t.transaction_date,
    t.total_value,
    t.units,
    t.channel,
    t.market_id,
    ci.customer_type,
    ci.risk_level,
    ci.investment_capacity,
    ai.asset_name,
    ai.asset_category,
    ai.sector
from transactions t
left join customer_info ci on t.customer_id = ci.customer_id
left join asset_info ai on t.isin = ai.isin
  );



  create or replace   view FAR_TRANS_DB.RAW.stg_transactions
  
   as (
    with source as (
    select * from FAR_TRANS_DB.raw.transactions
),

renamed as (
    select
        customerID as customer_id,
        ISIN as isin,
        transactionID as transaction_id,
        transactionType as transaction_type,
        timestamp::timestamp as transaction_date,
        totalValue::decimal(20,4) as total_value,
        units::decimal(20,4) as units,
        channel,
        marketID as market_id
    from source
)

select * from renamed
  );


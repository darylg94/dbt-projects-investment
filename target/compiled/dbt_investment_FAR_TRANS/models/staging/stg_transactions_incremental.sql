

with source as (
    select * from FAR_TRANS_DB.raw.transactions
    
    
        -- Only process new transactions since last run
        where timestamp > (select max(transaction_date) from FAR_TRANS_DB.staging.stg_transactions_incremental)
    
),

renamed as (
    select
        customerid as customer_id,
        isin,
        transactionid as transaction_id,
        transactiontype as transaction_type,
        timestamp::timestamp as transaction_date,
        totalvalue::decimal(20,4) as total_value,
        units::decimal(20,4) as units,
        channel,
        marketid as market_id,
        current_timestamp() as dbt_updated_at
    from source
)

select * from renamed
with source as (
    select * from {{ source('raw', 'markets') }}
),

renamed as (
    select
        exchangeID as exchange_id,
        marketID as market_id,
        name as market_name,
        description,
        country,
        tradingDays as trading_days,
        tradingHours as trading_hours,
        marketClass as market_class,
        current_timestamp() as valid_from,
        null as valid_to
    from source
)

select * from renamed
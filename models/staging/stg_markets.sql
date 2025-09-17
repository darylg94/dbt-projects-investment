with source as (
    select * from {{ source('raw', 'markets') }}
),

renamed as (
    select
        market_id,
        market_name,
        country,
        timezone,
        opening_time,
        closing_time,
        currency as base_currency,
        is_active::boolean as is_active,
        valid_from::timestamp as valid_from,
        lead(valid_from::timestamp) over (partition by market_id order by valid_from) as valid_to
    from source
)

select * from renamed


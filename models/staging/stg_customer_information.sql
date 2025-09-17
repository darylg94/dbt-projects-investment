with source as (
    select * from {{ source('raw', 'customer_information') }}
),

renamed as (
    select
        customerid as customer_id,
        customertype as customer_type,
        risklevel as risk_level,
        investmentcapacity as investment_capacity,
        lastquestionnairedate::date as last_questionnaire_date,
        timestamp::timestamp as valid_from,
        lead(timestamp::timestamp) over (partition by customerid order by timestamp) as valid_to
    from source
)

select * from renamed



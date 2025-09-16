with source as (
    select * from {{ source('raw', 'questionnaire') }}
),

renamed as (
    select
        questionnaire_id,
        customer_id,
        submission_date::timestamp as submission_date,
        investment_horizon,
        risk_tolerance_score::integer as risk_tolerance_score,
        investment_knowledge::integer as investment_knowledge_level,
        income_bracket,
        investment_goal,
        loss_tolerance::decimal(5,2) as loss_tolerance_percentage,
        preferred_investment_types,
        timestamp::timestamp as valid_from,
        lead(timestamp::timestamp) over (partition by customer_id order by timestamp) as valid_to
    from source
)

select * from renamed

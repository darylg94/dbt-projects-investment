with customer_info as (
    select * from {{ ref('stg_customer_information') }}
    where valid_to is null  -- Get current customer information
),

latest_questionnaire as (
    select
        customer_id,
        risk_tolerance_score,
        investment_knowledge_level,
        loss_tolerance_percentage,
        investment_horizon,
        investment_goal,
        preferred_investment_types,
        row_number() over (partition by customer_id order by submission_date desc) as rn
    from {{ ref('stg_questionnaire') }}
    where valid_to is null  -- Get current questionnaire responses
    qualify rn = 1  -- Get only the latest questionnaire
)

select
    ci.customer_id,
    ci.customer_type,
    ci.risk_level,
    ci.investment_capacity,
    lq.risk_tolerance_score,
    lq.investment_knowledge_level,
    lq.loss_tolerance_percentage,
    lq.investment_horizon,
    lq.investment_goal,
    lq.preferred_investment_types,
    case
        when ci.risk_level = 'Income' and lq.risk_tolerance_score <= 2 then 'Aligned'
        when ci.risk_level = 'Balanced' and lq.risk_tolerance_score between 3 and 6 then 'Aligned'
        when ci.risk_level = 'Growth' and lq.risk_tolerance_score between 7 and 8 then 'Aligned'
        when ci.risk_level = 'Aggressive' and lq.risk_tolerance_score >= 9 then 'Aligned'
        else 'Misaligned'
    end as risk_alignment_status
from customer_info ci
left join latest_questionnaire lq on ci.customer_id = lq.customer_id


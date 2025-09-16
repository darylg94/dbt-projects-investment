with customer_profile as (
    select * from {{ ref('stg_customer_information') }}
    where valid_to is null
),

questionnaire_data as (
    select * from {{ ref('stg_questionnaire') }}
    where valid_to is null
    qualify row_number() over (partition by customer_id order by submission_date desc) = 1
),

risk_scoring as (
    select
        cp.customer_id,
        cp.customer_type,
        cp.risk_level,
        cp.investment_capacity,
        qd.risk_tolerance_score,
        qd.investment_knowledge_level,
        qd.loss_tolerance_percentage,
        qd.investment_horizon,
        case
            when qd.risk_tolerance_score <= {{ var('low_risk_max_score') }} then 'Conservative'
            when qd.risk_tolerance_score <= {{ var('medium_risk_max_score') }} then 'Moderate'
            when qd.risk_tolerance_score <= {{ var('high_risk_max_score') }} then 'Growth'
            else 'Aggressive'
        end as risk_profile,
        case
            when cp.investment_capacity >= {{ var('premium_investment_threshold') }} then true
            else false
        end as is_premium_eligible
    from customer_profile cp
    left join questionnaire_data qd on cp.customer_id = qd.customer_id
)

select
    *,
    case
        when risk_profile = 'Conservative' then 0.05
        when risk_profile = 'Moderate' then 0.10
        when risk_profile = 'Growth' then 0.15
        else 0.20
    end as max_portfolio_volatility,
    case
        when risk_profile = 'Conservative' then 0.20
        when risk_profile = 'Moderate' then 0.40
        when risk_profile = 'Growth' then 0.60
        else 0.80
    end as max_equity_allocation
from risk_scoring

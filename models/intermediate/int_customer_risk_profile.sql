with customer_info as (
    select * from {{ ref('stg_customer_information') }}
    where valid_to is null  -- Get current customer information
),

risk_scores as (
    select
        customer_id,
        customer_type,
        risk_level,
        investment_capacity,
        case
            when risk_level = 'Income' then 1
            when risk_level = 'Balanced' then 2
            when risk_level = 'Growth' then 3
            when risk_level = 'Aggressive' then 4
            else 0
        end as risk_score,
        case
            when investment_capacity = 'Predicted_CAP_LT30K' then 30000
            when investment_capacity = 'CAP_30K_80K' then 80000
            when investment_capacity = 'CAP_80K_300K' then 300000
            when investment_capacity = 'CAP_300K_1M' then 1000000
            when investment_capacity = 'CAP_GT1M' then 5000000
            else 0
        end as investment_capacity_amount
    from customer_info
)

select * from risk_scores

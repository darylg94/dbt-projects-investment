with customer_risk as (
    select * from {{ ref('int_customer_risk_profile') }}
),

customer_segments as (
    select
        customer_type,
        risk_level,
        count(*) as customer_count,
        avg(investment_capacity_amount) as avg_investment_capacity,
        min(investment_capacity_amount) as min_investment_capacity,
        max(investment_capacity_amount) as max_investment_capacity,
        avg(risk_score) as avg_risk_score
    from customer_risk
    group by 1,2
)

select * from customer_segments

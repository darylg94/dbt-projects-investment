-- Generic test to ensure risk levels are valid
{% test valid_risk_level(model, column_name) %}

with validation as (
    select
        {{ column_name }} as risk_level
    from {{ model }}
    where {{ column_name }} not in ('Income', 'Balanced', 'Growth', 'Aggressive')
)

select *
from validation

{% endtest %}

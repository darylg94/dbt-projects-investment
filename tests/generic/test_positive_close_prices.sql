-- Generic test to ensure close prices are positive
{% test positive_close_prices(model, column_name) %}

with validation as (
    select
        {{ column_name }} as close_price
    from {{ model }}
    where {{ column_name }} <= 0
)

select *
from validation

{% endtest %}

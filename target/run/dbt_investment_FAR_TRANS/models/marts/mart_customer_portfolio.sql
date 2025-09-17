
  create or replace   view FAR_TRANS_DB.RAW.mart_customer_portfolio
  
   as (
    with customer_transactions as (
    select * from FAR_TRANS_DB.RAW.int_customer_transactions
),

customer_portfolio as (
    select
        customer_id,
        customer_type,
        risk_level,
        investment_capacity,
        count(distinct transaction_id) as total_transactions,
        count(distinct isin) as unique_assets,
        sum(case when transaction_type = 'Buy' then total_value else 0 end) as total_purchases,
        sum(case when transaction_type = 'Sell' then total_value else 0 end) as total_sales,
        sum(case when transaction_type = 'Buy' then total_value else -total_value end) as net_investment,
        count(distinct asset_category) as asset_categories_traded,
        count(distinct sector) as sectors_invested,
        min(transaction_date) as first_transaction_date,
        max(transaction_date) as last_transaction_date
    from customer_transactions
    group by 1,2,3,4
)

select * from customer_portfolio
  );


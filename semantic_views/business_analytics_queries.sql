-- Business Analytics Queries using Semantic Views
-- Self-serve analytics examples for business users

USE DATABASE FAR_TRANS_DB;
USE SCHEMA MARTS;

-- ========================================
-- CUSTOMER 360 ANALYTICS
-- ========================================

-- 1. Customer Segmentation Dashboard
SELECT 
    customer_type,
    risk_level,
    activity_level,
    value_segment,
    COUNT(*) as customer_count,
    AVG(portfolio_value) as avg_portfolio_size,
    SUM(portfolio_value) as total_aum,
    AVG(total_transactions) as avg_transaction_frequency
FROM customer_analytics_view
GROUP BY customer_type, risk_level, activity_level, value_segment
ORDER BY total_aum DESC;

-- 2. Monthly Investment Trends
SELECT 
    transaction_month,
    customer_type,
    SUM(net_investment_impact) as monthly_net_flow,
    COUNT(DISTINCT customer_id) as active_customers,
    AVG(total_value) as avg_transaction_size,
    COUNT(*) as total_transactions
FROM transaction_analytics_view
WHERE transaction_month >= '2022-01'
GROUP BY transaction_month, customer_type
ORDER BY transaction_month, customer_type;

-- 3. Channel Performance Analysis
SELECT 
    channel,
    asset_category,
    COUNT(*) as transaction_count,
    SUM(total_value) as channel_volume,
    COUNT(DISTINCT customer_id) as unique_customers,
    AVG(total_value) as avg_transaction_size
FROM transaction_analytics_view
GROUP BY channel, asset_category
ORDER BY channel_volume DESC;

-- 4. Risk Profile vs Investment Behavior
SELECT 
    risk_level,
    asset_category,
    COUNT(DISTINCT customer_id) as customers,
    SUM(net_investment_impact) as net_investment,
    AVG(total_value) as avg_investment_size,
    COUNT(*) as total_trades
FROM transaction_analytics_view
GROUP BY risk_level, asset_category
ORDER BY risk_level, net_investment DESC;

-- 5. Customer Lifecycle Analysis
SELECT 
    value_segment,
    activity_level,
    COUNT(*) as customer_count,
    AVG(portfolio_value) as avg_portfolio_value,
    AVG(total_transactions) as avg_transaction_count,
    AVG(unique_assets) as avg_diversification
FROM customer_analytics_view
GROUP BY value_segment, activity_level
ORDER BY avg_portfolio_value DESC;

-- ========================================
-- ASSET PERFORMANCE ANALYTICS
-- ========================================

-- 6. Sector Performance Ranking
SELECT 
    sector,
    COUNT(*) as asset_count,
    AVG(avg_daily_return_pct) as sector_avg_return,
    AVG(daily_volatility_pct) as sector_avg_risk,
    AVG(sharpe_ratio) as sector_sharpe_ratio,
    AVG(total_return_pct) as sector_total_return
FROM asset_analytics_view
WHERE sector IS NOT NULL
GROUP BY sector
ORDER BY sector_avg_return DESC;

-- 7. Risk-Return Analysis by Asset Category
SELECT 
    asset_category,
    risk_category,
    COUNT(*) as asset_count,
    AVG(avg_daily_return_pct) as avg_return,
    AVG(daily_volatility_pct) as avg_volatility,
    MAX(total_return_pct) as best_asset_return,
    MIN(total_return_pct) as worst_asset_return,
    AVG(sharpe_ratio) as avg_sharpe_ratio
FROM asset_analytics_view
GROUP BY asset_category, risk_category
ORDER BY asset_category, avg_return DESC;

-- 8. Top Performing Assets by Sector
SELECT 
    sector,
    asset_name,
    asset_category,
    total_return_pct,
    daily_volatility_pct,
    sharpe_ratio,
    trading_days
FROM asset_analytics_view
WHERE sector IS NOT NULL
QUALIFY ROW_NUMBER() OVER (PARTITION BY sector ORDER BY total_return_pct DESC) <= 3
ORDER BY sector, total_return_pct DESC;

-- ========================================
-- COMBINED CUSTOMER & ASSET ANALYTICS
-- ========================================

-- 9. Customer Investment Preferences by Risk Profile
SELECT 
    c.risk_level,
    t.asset_category,
    t.sector,
    COUNT(DISTINCT c.customer_id) as customers,
    SUM(t.net_investment_impact) as total_investment,
    AVG(t.total_value) as avg_transaction_size,
    COUNT(*) as total_transactions
FROM customer_analytics_view c
JOIN transaction_analytics_view t ON c.customer_id = t.customer_id
GROUP BY c.risk_level, t.asset_category, t.sector
ORDER BY c.risk_level, total_investment DESC;

-- 10. Channel Effectiveness by Asset Performance
SELECT 
    t.channel,
    a.risk_category,
    COUNT(DISTINCT t.customer_id) as customers,
    SUM(t.total_value) as channel_volume,
    AVG(a.sharpe_ratio) as avg_risk_adjusted_return,
    COUNT(*) as transactions
FROM transaction_analytics_view t
JOIN asset_analytics_view a ON t.isin = a.isin
WHERE a.sharpe_ratio IS NOT NULL
GROUP BY t.channel, a.risk_category
ORDER BY channel_volume DESC;

-- ========================================
-- BUSINESS KPI DASHBOARD QUERIES
-- ========================================

-- 11. Executive Summary Dashboard
SELECT 
    'Total AUM' as metric,
    SUM(portfolio_value) as value,
    'USD' as currency
FROM customer_analytics_view

UNION ALL

SELECT 
    'Active Customers',
    COUNT(DISTINCT customer_id),
    'Count'
FROM customer_analytics_view

UNION ALL

SELECT 
    'Average Portfolio Size',
    AVG(portfolio_value),
    'USD'
FROM customer_analytics_view

UNION ALL

SELECT 
    'Total Transactions',
    SUM(total_transactions),
    'Count'
FROM customer_analytics_view;

-- 12. Monthly Business Performance
SELECT 
    transaction_month,
    COUNT(DISTINCT customer_id) as active_customers,
    SUM(total_value) as monthly_volume,
    SUM(net_investment_impact) as net_flow,
    AVG(total_value) as avg_transaction_size,
    COUNT(*) as total_transactions
FROM transaction_analytics_view
WHERE transaction_month >= '2022-01'
GROUP BY transaction_month
ORDER BY transaction_month;

-- 13. Risk Management Dashboard
SELECT 
    risk_level,
    COUNT(*) as customers,
    SUM(portfolio_value) as segment_aum,
    AVG(portfolio_value) as avg_portfolio_size,
    AVG(total_transactions) as avg_activity,
    AVG(unique_assets) as avg_diversification
FROM customer_analytics_view
GROUP BY risk_level
ORDER BY segment_aum DESC;

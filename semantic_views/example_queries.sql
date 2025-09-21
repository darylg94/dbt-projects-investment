-- Example Queries for Semantic Views
-- These demonstrate self-serve analytics capabilities using the semantic views

USE DATABASE FAR_TRANS_DB;
USE SCHEMA MARTS;

-- ========================================
-- CUSTOMER 360 ANALYTICS EXAMPLES
-- ========================================

-- 1. Customer Segmentation Analysis
SELECT 
    customer_type,
    risk_level,
    activity_level,
    COUNT(*) as customer_count,
    AVG(portfolio_value) as avg_portfolio_size,
    SUM(portfolio_aum) as total_aum
FROM customer_360_analytics
GROUP BY customer_type, risk_level, activity_level
ORDER BY total_aum DESC;

-- 2. Investment Flow by Customer Segment
SELECT 
    customer_type,
    transaction_month,
    SUM(net_investment_flow) as monthly_net_flow,
    COUNT(customer_count) as active_customers,
    AVG(average_transaction_size) as avg_trade_size
FROM customer_360_analytics
WHERE transaction_month >= '2022-01'
GROUP BY customer_type, transaction_month
ORDER BY transaction_month, customer_type;

-- 3. Channel Performance Analysis
SELECT 
    channel,
    asset_category,
    SUM(total_revenue) as channel_volume,
    COUNT(customer_count) as customers_using_channel,
    AVG(average_transaction_size) as avg_transaction_size
FROM customer_360_analytics
GROUP BY channel, asset_category
ORDER BY channel_volume DESC;

-- 4. Risk Profile vs Investment Behavior
SELECT 
    risk_level,
    asset_category,
    COUNT(customer_count) as customers,
    SUM(net_investment_flow) as net_investment,
    AVG(diversification_score) as avg_diversification
FROM customer_360_analytics
GROUP BY risk_level, asset_category
ORDER BY risk_level, net_investment DESC;

-- 5. Customer Value Segmentation
SELECT 
    value_segment,
    diversification_level,
    COUNT(*) as customer_count,
    AVG(portfolio_aum) as avg_aum,
    SUM(transaction_frequency) as total_transactions
FROM customer_360_analytics
GROUP BY value_segment, diversification_level
ORDER BY avg_aum DESC;

-- ========================================
-- ASSET PERFORMANCE ANALYTICS EXAMPLES
-- ========================================

-- 6. Sector Performance Comparison
SELECT 
    sector,
    COUNT(*) as asset_count,
    AVG(average_daily_return) as sector_avg_return,
    AVG(portfolio_volatility) as sector_avg_risk,
    AVG(average_sharpe_ratio) as sector_sharpe_ratio
FROM asset_performance_analytics
WHERE sector IS NOT NULL
GROUP BY sector
ORDER BY sector_avg_return DESC;

-- 7. Risk-Return Analysis by Asset Category
SELECT 
    asset_category,
    risk_category,
    COUNT(*) as asset_count,
    AVG(average_daily_return) as avg_return,
    AVG(portfolio_volatility) as avg_volatility,
    MAX(best_performing_return) as best_asset_return,
    MIN(worst_performing_return) as worst_asset_return
FROM asset_performance_analytics
GROUP BY asset_category, risk_category
ORDER BY asset_category, avg_return DESC;

-- 8. Monthly Performance Trends
SELECT 
    price_month,
    asset_category,
    COUNT(*) as observations,
    AVG(average_daily_return) as monthly_avg_return,
    STDDEV(average_daily_return) as return_dispersion
FROM asset_performance_analytics
WHERE price_month >= '2022-01'
GROUP BY price_month, asset_category
ORDER BY price_month, asset_category;

-- 9. Top Performing Assets by Sector
SELECT 
    sector,
    asset_name,
    total_return_pct,
    volatility_pct,
    sharpe_ratio,
    win_rate_pct
FROM asset_performance_analytics
WHERE sector IS NOT NULL
QUALIFY ROW_NUMBER() OVER (PARTITION BY sector ORDER BY total_return_pct DESC) <= 3
ORDER BY sector, total_return_pct DESC;

-- 10. Risk-Adjusted Performance Rankings
SELECT 
    asset_name,
    asset_category,
    sector,
    total_return_pct,
    volatility_pct,
    sharpe_ratio,
    RANK() OVER (ORDER BY sharpe_ratio DESC) as sharpe_rank,
    RANK() OVER (ORDER BY total_return_pct DESC) as return_rank
FROM asset_performance_analytics
WHERE sharpe_ratio IS NOT NULL
ORDER BY sharpe_ratio DESC
LIMIT 20;

-- ========================================
-- COMBINED ANALYTICS EXAMPLES
-- ========================================

-- 11. Customer Investment Preferences by Risk Profile
SELECT 
    c.risk_level,
    a.asset_category,
    a.sector,
    COUNT(DISTINCT c.customer_id) as customers,
    SUM(c.net_investment_flow) as total_investment,
    AVG(a.average_daily_return) as asset_avg_return,
    AVG(a.portfolio_volatility) as asset_avg_risk
FROM customer_360_analytics c
JOIN asset_performance_analytics a ON c.asset_category = a.asset_category
GROUP BY c.risk_level, a.asset_category, a.sector
ORDER BY c.risk_level, total_investment DESC;

-- 12. Channel Effectiveness by Asset Performance
SELECT 
    c.channel,
    a.risk_category,
    COUNT(DISTINCT c.customer_id) as customers,
    SUM(c.total_revenue) as channel_volume,
    AVG(a.average_sharpe_ratio) as avg_risk_adjusted_return
FROM customer_360_analytics c
JOIN asset_performance_analytics a ON c.asset_category = a.asset_category
GROUP BY c.channel, a.risk_category
ORDER BY channel_volume DESC;

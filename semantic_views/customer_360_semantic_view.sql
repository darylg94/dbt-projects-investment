-- Customer 360 Semantic View for Self-Serve Analytics
-- Based on Snowflake Semantic Views: https://docs.snowflake.com/en/user-guide/views-semantic/overview

USE DATABASE FAR_TRANS_DB;
USE SCHEMA MARTS;

-- Create Customer 360 Semantic View
CREATE OR REPLACE SEMANTIC VIEW customer_360_analytics
AS (
    -- Define logical tables (business entities)
    LOGICAL_TABLES => [
        {
            name: 'customers',
            description: 'Customer profiles and demographics',
            base_table: 'FAR_TRANS_DB.STAGING.STG_CUSTOMER_INFORMATION',
            dimensions: [
                {
                    name: 'customer_id',
                    type: 'TEXT',
                    expr: 'customer_id',
                    description: 'Unique customer identifier'
                },
                {
                    name: 'customer_type',
                    type: 'TEXT', 
                    expr: 'customer_type',
                    description: 'Customer segment (Premium or Mass)',
                    synonyms: ['customer_segment', 'client_type']
                },
                {
                    name: 'risk_level',
                    type: 'TEXT',
                    expr: 'risk_level', 
                    description: 'Customer risk tolerance level',
                    synonyms: ['risk_tolerance', 'risk_profile']
                },
                {
                    name: 'investment_capacity',
                    type: 'TEXT',
                    expr: 'investment_capacity',
                    description: 'Investment capacity bracket',
                    synonyms: ['investment_bracket', 'capacity_level']
                },
                {
                    name: 'customer_tenure_days',
                    type: 'NUMBER',
                    expr: 'datediff(day, valid_from, current_date())',
                    description: 'Days since customer onboarding'
                }
            ]
        },
        {
            name: 'transactions',
            description: 'Customer transaction history',
            base_table: 'FAR_TRANS_DB.INTERMEDIATE.INT_CUSTOMER_TRANSACTIONS',
            dimensions: [
                {
                    name: 'transaction_id',
                    type: 'TEXT',
                    expr: 'transaction_id',
                    description: 'Unique transaction identifier'
                },
                {
                    name: 'transaction_type',
                    type: 'TEXT',
                    expr: 'transaction_type',
                    description: 'Buy or Sell transaction',
                    synonyms: ['trade_type', 'order_type']
                },
                {
                    name: 'transaction_date',
                    type: 'TIMESTAMP',
                    expr: 'transaction_date',
                    description: 'Date and time of transaction'
                },
                {
                    name: 'transaction_month',
                    type: 'TEXT',
                    expr: 'to_char(transaction_date, \'YYYY-MM\')',
                    description: 'Transaction month (YYYY-MM format)'
                },
                {
                    name: 'transaction_quarter',
                    type: 'TEXT',
                    expr: 'to_char(transaction_date, \'YYYY-Q"Q"\')',
                    description: 'Transaction quarter'
                },
                {
                    name: 'asset_category',
                    type: 'TEXT',
                    expr: 'asset_category',
                    description: 'Category of traded asset',
                    synonyms: ['investment_type', 'asset_class']
                },
                {
                    name: 'sector',
                    type: 'TEXT',
                    expr: 'sector',
                    description: 'Business sector of the asset'
                },
                {
                    name: 'channel',
                    type: 'TEXT',
                    expr: 'channel',
                    description: 'Transaction channel used',
                    synonyms: ['trading_channel', 'platform']
                }
            ],
            facts: [
                {
                    name: 'transaction_value',
                    type: 'NUMBER',
                    expr: 'total_value',
                    description: 'Individual transaction value'
                },
                {
                    name: 'transaction_units',
                    type: 'NUMBER', 
                    expr: 'units',
                    description: 'Number of units traded'
                },
                {
                    name: 'net_investment_impact',
                    type: 'NUMBER',
                    expr: 'case when transaction_type = \'Buy\' then total_value else -total_value end',
                    description: 'Net investment impact (positive for buys, negative for sells)'
                }
            ]
        },
        {
            name: 'portfolios',
            description: 'Customer portfolio summaries',
            base_table: 'FAR_TRANS_DB.MARTS.MART_CUSTOMER_PORTFOLIO',
            dimensions: [
                {
                    name: 'activity_level',
                    type: 'TEXT',
                    expr: 'case 
                        when total_transactions >= 50 then \'High Activity\'
                        when total_transactions >= 20 then \'Medium Activity\'
                        when total_transactions >= 5 then \'Low Activity\'
                        else \'Minimal Activity\'
                    end',
                    description: 'Customer activity classification',
                    synonyms: ['trading_activity', 'engagement_level']
                },
                {
                    name: 'value_segment',
                    type: 'TEXT',
                    expr: 'case 
                        when abs(net_investment) >= 100000 then \'High Value\'
                        when abs(net_investment) >= 50000 then \'Medium Value\'
                        when abs(net_investment) >= 10000 then \'Low Value\'
                        else \'Minimal Value\'
                    end',
                    description: 'Customer value segment based on portfolio size'
                },
                {
                    name: 'diversification_level',
                    type: 'TEXT',
                    expr: 'case 
                        when unique_assets >= 10 then \'Well Diversified\'
                        when unique_assets >= 5 then \'Moderately Diversified\'
                        when unique_assets >= 2 then \'Limited Diversification\'
                        else \'Single Asset\'
                    end',
                    description: 'Portfolio diversification assessment'
                }
            ],
            facts: [
                {
                    name: 'portfolio_value',
                    type: 'NUMBER',
                    expr: 'abs(net_investment)',
                    description: 'Total portfolio value'
                },
                {
                    name: 'transaction_count',
                    type: 'NUMBER',
                    expr: 'total_transactions',
                    description: 'Total number of transactions'
                },
                {
                    name: 'asset_count',
                    type: 'NUMBER',
                    expr: 'unique_assets',
                    description: 'Number of unique assets in portfolio'
                },
                {
                    name: 'purchase_amount',
                    type: 'NUMBER',
                    expr: 'total_purchases',
                    description: 'Total amount of purchases'
                },
                {
                    name: 'sales_amount',
                    type: 'NUMBER',
                    expr: 'total_sales',
                    description: 'Total amount of sales'
                }
            ]
        },
        {
            name: 'assets',
            description: 'Asset performance and characteristics',
            base_table: 'FAR_TRANS_DB.MARTS.MART_ASSET_PERFORMANCE',
            dimensions: [
                {
                    name: 'asset_name',
                    type: 'TEXT',
                    expr: 'asset_name',
                    description: 'Full name of the financial asset'
                },
                {
                    name: 'asset_category',
                    type: 'TEXT',
                    expr: 'asset_category',
                    description: 'Category of the asset',
                    synonyms: ['asset_type', 'investment_type']
                },
                {
                    name: 'sector',
                    type: 'TEXT',
                    expr: 'sector',
                    description: 'Business sector'
                },
                {
                    name: 'industry',
                    type: 'TEXT',
                    expr: 'industry',
                    description: 'Specific industry classification'
                },
                {
                    name: 'volatility_category',
                    type: 'TEXT',
                    expr: 'case 
                        when daily_volatility < 0.01 then \'Low Risk\'
                        when daily_volatility < 0.02 then \'Medium Risk\'
                        else \'High Risk\'
                    end',
                    description: 'Risk category based on volatility'
                }
            ],
            facts: [
                {
                    name: 'average_return',
                    type: 'NUMBER',
                    expr: 'avg_daily_return',
                    description: 'Average daily return percentage'
                },
                {
                    name: 'volatility',
                    type: 'NUMBER',
                    expr: 'daily_volatility',
                    description: 'Daily volatility (risk measure)'
                },
                {
                    name: 'total_return',
                    type: 'NUMBER',
                    expr: 'total_return',
                    description: 'Total return from min to max price'
                },
                {
                    name: 'trading_days',
                    type: 'NUMBER',
                    expr: 'trading_days',
                    description: 'Number of trading days with data'
                }
            ]
        }
    ],
    
    -- Define relationships between logical tables
    RELATIONSHIPS => [
        {
            name: 'customer_to_transactions',
            from_table: 'customers',
            to_table: 'transactions', 
            join_keys: [['customer_id', 'customer_id']],
            description: 'Link customers to their transactions'
        },
        {
            name: 'customer_to_portfolios',
            from_table: 'customers',
            to_table: 'portfolios',
            join_keys: [['customer_id', 'customer_id']],
            description: 'Link customers to their portfolio summaries'
        },
        {
            name: 'transactions_to_assets',
            from_table: 'transactions',
            to_table: 'assets',
            join_keys: [['isin', 'isin']],
            description: 'Link transactions to asset performance data'
        }
    ],
    
    -- Define business metrics
    METRICS => [
        {
            name: 'total_revenue',
            type: 'NUMBER',
            expr: 'SUM(transaction_value)',
            description: 'Total transaction volume',
            synonyms: ['revenue', 'transaction_volume', 'trading_volume']
        },
        {
            name: 'net_investment_flow',
            type: 'NUMBER',
            expr: 'SUM(net_investment_impact)',
            description: 'Net investment flow (buys minus sells)',
            synonyms: ['net_flow', 'investment_flow']
        },
        {
            name: 'average_transaction_size',
            type: 'NUMBER',
            expr: 'AVG(transaction_value)',
            description: 'Average transaction size',
            synonyms: ['avg_trade_size', 'mean_transaction_value']
        },
        {
            name: 'customer_count',
            type: 'NUMBER',
            expr: 'COUNT(DISTINCT customer_id)',
            description: 'Number of unique customers',
            synonyms: ['unique_customers', 'customer_base']
        },
        {
            name: 'portfolio_aum',
            type: 'NUMBER',
            expr: 'SUM(portfolio_value)',
            description: 'Total Assets Under Management',
            synonyms: ['aum', 'total_portfolio_value', 'assets_under_management']
        },
        {
            name: 'average_portfolio_size',
            type: 'NUMBER',
            expr: 'AVG(portfolio_value)',
            description: 'Average portfolio size per customer',
            synonyms: ['avg_portfolio_value', 'mean_portfolio_size']
        },
        {
            name: 'diversification_score',
            type: 'NUMBER',
            expr: 'AVG(asset_count)',
            description: 'Average number of assets per customer',
            synonyms: ['avg_diversification', 'portfolio_breadth']
        },
        {
            name: 'transaction_frequency',
            type: 'NUMBER',
            expr: 'COUNT(*)',
            description: 'Total number of transactions',
            synonyms: ['trade_count', 'transaction_count']
        }
    ]
);

-- Grant usage privileges for self-serve analytics
GRANT USAGE ON SEMANTIC VIEW customer_360_analytics TO ROLE PUBLIC;
GRANT USAGE ON SEMANTIC VIEW customer_360_analytics TO ROLE FAR_TRANS_DBT_ROLE;

-- Show the created semantic view
DESCRIBE SEMANTIC VIEW customer_360_analytics;

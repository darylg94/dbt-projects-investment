-- Asset Performance Semantic View for Investment Analytics
-- Based on Snowflake Semantic Views: https://docs.snowflake.com/en/user-guide/views-semantic/overview

USE DATABASE FAR_TRANS_DB;
USE SCHEMA MARTS;

-- Create Asset Performance Semantic View
CREATE OR REPLACE SEMANTIC VIEW asset_performance_analytics
AS (
    -- Define logical tables for asset analysis
    LOGICAL_TABLES => [
        {
            name: 'daily_metrics',
            description: 'Daily asset price and performance metrics',
            base_table: 'FAR_TRANS_DB.INTERMEDIATE.INT_ASSET_DAILY_METRICS',
            dimensions: [
                {
                    name: 'asset_identifier',
                    type: 'TEXT',
                    expr: 'isin',
                    description: 'International Securities Identification Number',
                    synonyms: ['isin', 'security_id', 'asset_id']
                },
                {
                    name: 'asset_name',
                    type: 'TEXT',
                    expr: 'asset_name',
                    description: 'Full name of the asset',
                    synonyms: ['security_name', 'instrument_name']
                },
                {
                    name: 'asset_category',
                    type: 'TEXT',
                    expr: 'asset_category',
                    description: 'Asset category (Stock, Bond, MTF)',
                    synonyms: ['asset_type', 'security_type', 'instrument_type']
                },
                {
                    name: 'sector',
                    type: 'TEXT',
                    expr: 'sector',
                    description: 'Business sector classification'
                },
                {
                    name: 'industry',
                    type: 'TEXT',
                    expr: 'industry',
                    description: 'Specific industry classification'
                },
                {
                    name: 'price_date',
                    type: 'DATE',
                    expr: 'price_date::date',
                    description: 'Date of price observation'
                },
                {
                    name: 'price_month',
                    type: 'TEXT',
                    expr: 'to_char(price_date, \'YYYY-MM\')',
                    description: 'Price month (YYYY-MM format)'
                },
                {
                    name: 'price_year',
                    type: 'NUMBER',
                    expr: 'extract(year from price_date)',
                    description: 'Price year'
                }
            ],
            facts: [
                {
                    name: 'closing_price',
                    type: 'NUMBER',
                    expr: 'close_price',
                    description: 'Daily closing price'
                },
                {
                    name: 'daily_return_pct',
                    type: 'NUMBER',
                    expr: 'daily_return * 100',
                    description: 'Daily return as percentage'
                },
                {
                    name: 'price_change',
                    type: 'NUMBER',
                    expr: 'close_price - prev_close_price',
                    description: 'Absolute price change from previous day'
                }
            ]
        },
        {
            name: 'asset_summary',
            description: 'Asset performance summary statistics',
            base_table: 'FAR_TRANS_DB.MARTS.MART_ASSET_PERFORMANCE',
            dimensions: [
                {
                    name: 'asset_identifier',
                    type: 'TEXT',
                    expr: 'isin',
                    description: 'International Securities Identification Number'
                },
                {
                    name: 'asset_name',
                    type: 'TEXT',
                    expr: 'asset_name',
                    description: 'Full name of the asset'
                },
                {
                    name: 'asset_category',
                    type: 'TEXT',
                    expr: 'asset_category',
                    description: 'Asset category'
                },
                {
                    name: 'sector',
                    type: 'TEXT',
                    expr: 'sector',
                    description: 'Business sector'
                },
                {
                    name: 'risk_category',
                    type: 'TEXT',
                    expr: 'case 
                        when daily_volatility < 0.01 then \'Low Risk\'
                        when daily_volatility < 0.02 then \'Medium Risk\'
                        else \'High Risk\'
                    end',
                    description: 'Risk classification based on volatility',
                    synonyms: ['volatility_level', 'risk_level']
                }
            ],
            facts: [
                {
                    name: 'total_return_pct',
                    type: 'NUMBER',
                    expr: 'total_return * 100',
                    description: 'Total return percentage over the period'
                },
                {
                    name: 'volatility_pct',
                    type: 'NUMBER',
                    expr: 'daily_volatility * 100',
                    description: 'Daily volatility as percentage'
                },
                {
                    name: 'sharpe_ratio',
                    type: 'NUMBER',
                    expr: 'case when daily_volatility > 0 then avg_daily_return / daily_volatility else null end',
                    description: 'Risk-adjusted return measure'
                },
                {
                    name: 'win_rate_pct',
                    type: 'NUMBER',
                    expr: 'win_rate * 100',
                    description: 'Percentage of days with positive returns'
                }
            ]
        }
    ],
    
    -- Define relationships
    RELATIONSHIPS => [
        {
            name: 'daily_to_summary',
            from_table: 'daily_metrics',
            to_table: 'asset_summary',
            join_keys: [['asset_identifier', 'asset_identifier']],
            description: 'Link daily metrics to summary statistics'
        }
    ],
    
    -- Define business metrics for asset analysis
    METRICS => [
        {
            name: 'average_daily_return',
            type: 'NUMBER',
            expr: 'AVG(daily_return_pct)',
            description: 'Average daily return across all assets',
            synonyms: ['mean_return', 'avg_performance']
        },
        {
            name: 'portfolio_volatility',
            type: 'NUMBER',
            expr: 'AVG(volatility_pct)',
            description: 'Average volatility across assets',
            synonyms: ['average_risk', 'mean_volatility']
        },
        {
            name: 'best_performing_return',
            type: 'NUMBER',
            expr: 'MAX(total_return_pct)',
            description: 'Highest total return among assets',
            synonyms: ['top_performance', 'best_return']
        },
        {
            name: 'worst_performing_return',
            type: 'NUMBER',
            expr: 'MIN(total_return_pct)',
            description: 'Lowest total return among assets',
            synonyms: ['worst_performance', 'poorest_return']
        },
        {
            name: 'average_sharpe_ratio',
            type: 'NUMBER',
            expr: 'AVG(sharpe_ratio)',
            description: 'Average risk-adjusted return measure',
            synonyms: ['mean_sharpe', 'avg_risk_adjusted_return']
        }
    ]
);

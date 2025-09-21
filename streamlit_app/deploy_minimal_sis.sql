-- Deploy Minimal Customer 360 Analytics to Streamlit in Snowflake
-- Uses only pre-installed packages (streamlit, pandas, numpy)

USE ROLE ACCOUNTADMIN;
USE DATABASE FAR_TRANS_DB;
USE WAREHOUSE FAR_TRANS_WH;

-- Create schema for Streamlit apps
CREATE SCHEMA IF NOT EXISTS STREAMLIT_APPS;
USE SCHEMA STREAMLIT_APPS;

-- Grant necessary privileges
GRANT USAGE ON DATABASE FAR_TRANS_DB TO ROLE PUBLIC;
GRANT USAGE ON SCHEMA FAR_TRANS_DB.STREAMLIT_APPS TO ROLE PUBLIC;
GRANT USAGE ON SCHEMA FAR_TRANS_DB.MARTS TO ROLE PUBLIC;
GRANT USAGE ON SCHEMA FAR_TRANS_DB.INTERMEDIATE TO ROLE PUBLIC;
GRANT SELECT ON ALL TABLES IN SCHEMA FAR_TRANS_DB.MARTS TO ROLE PUBLIC;
GRANT SELECT ON ALL TABLES IN SCHEMA FAR_TRANS_DB.INTERMEDIATE TO ROLE PUBLIC;
GRANT USAGE ON WAREHOUSE FAR_TRANS_WH TO ROLE PUBLIC;

-- Create Streamlit app with minimal dependencies
CREATE OR REPLACE STREAMLIT customer_360_analytics
    QUERY_WAREHOUSE = FAR_TRANS_WH
    COMMENT = 'Customer 360 Analytics Dashboard - Minimal SIS Version'
AS
$$
import streamlit as st
import pandas as pd

# Page configuration
st.set_page_config(
    page_title="Customer 360 Analytics",
    page_icon="📊",
    layout="wide"
)

# Get Snowflake session
@st.cache_resource
def get_session():
    return st.connection('snowflake').session()

@st.cache_data(ttl=600)
def run_query(query):
    try:
        session = get_session()
        result = session.sql(query).collect()
        if result:
            df = pd.DataFrame([row.asDict() for row in result])
            return df
        return pd.DataFrame()
    except Exception as e:
        st.error(f"Error: {e}")
        return pd.DataFrame()

# Initialize context
session = get_session()
session.sql("USE DATABASE FAR_TRANS_DB").collect()
session.sql("USE SCHEMA MARTS").collect()

st.title("🏦 Customer 360 Analytics Dashboard")
st.markdown("*Investment Analytics Platform - Powered by DBT & Snowflake*")

# Executive Summary
st.header("📊 Executive Summary")

col1, col2, col3, col4 = st.columns(4)

# Total AUM
aum_query = "SELECT SUM(ABS(NET_INVESTMENT)) as total_aum FROM MART_CUSTOMER_PORTFOLIO WHERE NET_INVESTMENT IS NOT NULL"
aum_data = run_query(aum_query)

with col1:
    if not aum_data.empty and aum_data['TOTAL_AUM'].iloc[0] is not None:
        st.metric("💰 Total AUM", f"${aum_data['TOTAL_AUM'].iloc[0]:,.0f}")
    else:
        st.metric("💰 Total AUM", "No data")

# Customer count
customers_query = "SELECT COUNT(*) as customer_count FROM MART_CUSTOMER_PORTFOLIO"
customers_data = run_query(customers_query)

with col2:
    if not customers_data.empty:
        st.metric("👥 Total Customers", f"{customers_data['CUSTOMER_COUNT'].iloc[0]:,}")

# Average portfolio
avg_query = "SELECT AVG(ABS(NET_INVESTMENT)) as avg_portfolio FROM MART_CUSTOMER_PORTFOLIO WHERE NET_INVESTMENT IS NOT NULL"
avg_data = run_query(avg_query)

with col3:
    if not avg_data.empty and avg_data['AVG_PORTFOLIO'].iloc[0] is not None:
        st.metric("📈 Avg Portfolio", f"${avg_data['AVG_PORTFOLIO'].iloc[0]:,.0f}")
    else:
        st.metric("📈 Avg Portfolio", "No data")

# Total transactions
txn_query = "SELECT SUM(TOTAL_TRANSACTIONS) as total_txns FROM MART_CUSTOMER_PORTFOLIO WHERE TOTAL_TRANSACTIONS IS NOT NULL"
txn_data = run_query(txn_query)

with col4:
    if not txn_data.empty and txn_data['TOTAL_TXNS'].iloc[0] is not None:
        st.metric("🔄 Total Transactions", f"{txn_data['TOTAL_TXNS'].iloc[0]:,}")
    else:
        st.metric("🔄 Total Transactions", "No data")

# Customer Segmentation
st.header("👥 Customer Segmentation")

segmentation_query = """
SELECT 
    CUSTOMER_TYPE,
    RISK_LEVEL,
    COUNT(*) as customer_count,
    AVG(ABS(NET_INVESTMENT)) as avg_portfolio_size,
    SUM(ABS(NET_INVESTMENT)) as total_aum
FROM MART_CUSTOMER_PORTFOLIO
WHERE NET_INVESTMENT IS NOT NULL
GROUP BY CUSTOMER_TYPE, RISK_LEVEL
ORDER BY total_aum DESC
"""

segmentation_data = run_query(segmentation_query)

if not segmentation_data.empty:
    col1, col2 = st.columns(2)
    
    with col1:
        st.subheader("📊 AUM by Customer Type")
        aum_by_type = segmentation_data.groupby('CUSTOMER_TYPE')['TOTAL_AUM'].sum()
        st.bar_chart(aum_by_type, height=300)
    
    with col2:
        st.subheader("📊 Customer Count by Risk Level")
        count_by_risk = segmentation_data.groupby('RISK_LEVEL')['CUSTOMER_COUNT'].sum()
        st.bar_chart(count_by_risk, height=300)
    
    # Segmentation details
    st.subheader("📋 Customer Segmentation Details")
    formatted_seg = segmentation_data.copy()
    formatted_seg['AVG_PORTFOLIO_SIZE'] = formatted_seg['AVG_PORTFOLIO_SIZE'].apply(lambda x: f"${x:,.0f}" if pd.notna(x) else "N/A")
    formatted_seg['TOTAL_AUM'] = formatted_seg['TOTAL_AUM'].apply(lambda x: f"${x:,.0f}" if pd.notna(x) else "N/A")
    st.dataframe(formatted_seg, use_container_width=True)

# Asset Performance
st.header("📈 Asset Performance")

asset_performance_query = """
SELECT 
    ASSET_CATEGORY,
    COUNT(*) as asset_count,
    AVG(COALESCE(AVG_DAILY_RETURN, 0) * 100) as avg_return_pct,
    AVG(COALESCE(DAILY_VOLATILITY, 0) * 100) as avg_volatility_pct
FROM MART_ASSET_PERFORMANCE
GROUP BY ASSET_CATEGORY
ORDER BY avg_return_pct DESC
"""

asset_data = run_query(asset_performance_query)

if not asset_data.empty:
    col1, col2 = st.columns(2)
    
    with col1:
        st.subheader("📊 Average Return by Asset Category")
        st.bar_chart(asset_data.set_index('ASSET_CATEGORY')['AVG_RETURN_PCT'], height=300)
    
    with col2:
        st.subheader("📊 Average Volatility by Asset Category")
        st.bar_chart(asset_data.set_index('ASSET_CATEGORY')['AVG_VOLATILITY_PCT'], height=300)
    
    # Asset performance details
    st.subheader("📋 Asset Performance Summary")
    formatted_assets = asset_data.copy()
    formatted_assets['AVG_RETURN_PCT'] = formatted_assets['AVG_RETURN_PCT'].apply(lambda x: f"{x:.4f}%" if pd.notna(x) else "N/A")
    formatted_assets['AVG_VOLATILITY_PCT'] = formatted_assets['AVG_VOLATILITY_PCT'].apply(lambda x: f"{x:.4f}%" if pd.notna(x) else "N/A")
    st.dataframe(formatted_assets, use_container_width=True)

# Portfolio Analysis
st.header("💼 Portfolio Analysis")

portfolio_analysis_query = """
SELECT 
    CASE 
        WHEN UNIQUE_ASSETS >= 10 THEN 'Well Diversified (10+)'
        WHEN UNIQUE_ASSETS >= 5 THEN 'Moderately Diversified (5-9)'
        WHEN UNIQUE_ASSETS >= 2 THEN 'Limited Diversification (2-4)'
        ELSE 'Single Asset (1)'
    END as diversification_level,
    COUNT(*) as customer_count,
    AVG(ABS(NET_INVESTMENT)) as avg_portfolio_value
FROM MART_CUSTOMER_PORTFOLIO
WHERE NET_INVESTMENT IS NOT NULL
GROUP BY diversification_level
ORDER BY avg_portfolio_value DESC
"""

portfolio_data = run_query(portfolio_analysis_query)

if not portfolio_data.empty:
    col1, col2 = st.columns(2)
    
    with col1:
        st.subheader("📊 Customer Count by Diversification")
        st.bar_chart(portfolio_data.set_index('DIVERSIFICATION_LEVEL')['CUSTOMER_COUNT'], height=300)
    
    with col2:
        st.subheader("📊 Portfolio Value by Diversification")
        st.bar_chart(portfolio_data.set_index('DIVERSIFICATION_LEVEL')['AVG_PORTFOLIO_VALUE'], height=300)
    
    # Portfolio details
    st.subheader("📋 Portfolio Diversification Details")
    formatted_portfolio = portfolio_data.copy()
    formatted_portfolio['AVG_PORTFOLIO_VALUE'] = formatted_portfolio['AVG_PORTFOLIO_VALUE'].apply(lambda x: f"${x:,.0f}" if pd.notna(x) else "N/A")
    st.dataframe(formatted_portfolio, use_container_width=True)

# Top Customers
st.header("🏆 Top Customer Portfolios")

top_customers_query = """
SELECT 
    CUSTOMER_TYPE,
    RISK_LEVEL,
    ABS(NET_INVESTMENT) as portfolio_value,
    TOTAL_TRANSACTIONS,
    UNIQUE_ASSETS,
    ASSET_CATEGORIES_TRADED
FROM MART_CUSTOMER_PORTFOLIO
WHERE NET_INVESTMENT IS NOT NULL
ORDER BY portfolio_value DESC
LIMIT 20
"""

top_customers = run_query(top_customers_query)

if not top_customers.empty:
    formatted_customers = top_customers.copy()
    formatted_customers['PORTFOLIO_VALUE'] = formatted_customers['PORTFOLIO_VALUE'].apply(lambda x: f"${x:,.0f}" if pd.notna(x) else "N/A")
    st.dataframe(formatted_customers, use_container_width=True)

st.markdown("---")
st.markdown("*Dashboard powered by DBT, Snowflake, and Streamlit in Snowflake*")
$$;

-- Grant usage to view the app
GRANT USAGE ON STREAMLIT customer_360_analytics TO ROLE PUBLIC;

-- Show the created app
SHOW STREAMLITS;

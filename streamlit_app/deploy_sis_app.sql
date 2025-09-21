-- Deploy Streamlit in Snowflake (SIS) App
-- Based on: https://docs.snowflake.com/en/developer-guide/streamlit/getting-started

USE ROLE ACCOUNTADMIN;
USE DATABASE FAR_TRANS_DB;
USE WAREHOUSE FAR_TRANS_WH;

-- Create a dedicated schema for Streamlit apps
CREATE SCHEMA IF NOT EXISTS STREAMLIT_APPS;
USE SCHEMA STREAMLIT_APPS;

-- Create stage for Streamlit app files
CREATE OR REPLACE STAGE streamlit_stage
    DIRECTORY = (ENABLE = TRUE)
    COMMENT = 'Stage for Customer 360 Analytics Streamlit app files';

-- Upload Streamlit app files to stage
-- PUT file://customer_360_dashboard.py @streamlit_stage/customer_360_analytics/ AUTO_COMPRESS=FALSE;
-- PUT file://environment.yml @streamlit_stage/customer_360_analytics/ AUTO_COMPRESS=FALSE;
-- PUT file://pages/1_🎯_Customer_Segmentation.py @streamlit_stage/customer_360_analytics/pages/ AUTO_COMPRESS=FALSE;
-- PUT file://pages/2_📈_Asset_Performance.py @streamlit_stage/customer_360_analytics/pages/ AUTO_COMPRESS=FALSE;
-- PUT file://pages/3_💰_Transaction_Analytics.py @streamlit_stage/customer_360_analytics/pages/ AUTO_COMPRESS=FALSE;

-- Create Streamlit app from stage
CREATE OR REPLACE STREAMLIT customer_360_analytics
    ROOT_LOCATION = '@streamlit_stage/customer_360_analytics'
    MAIN_FILE = 'customer_360_dashboard.py'
    QUERY_WAREHOUSE = FAR_TRANS_WH
    COMMENT = 'Customer 360 Analytics Dashboard for Investment Platform';

-- Alternative: Create Streamlit app with inline code
CREATE OR REPLACE STREAMLIT customer_360_analytics_simple
    MAIN_FILE = 'customer_360_dashboard.py'
    QUERY_WAREHOUSE = FAR_TRANS_WH
AS
$$
import streamlit as st
import pandas as pd
import plotly.express as px
from datetime import datetime, timedelta

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

# Executive Summary
st.header("📊 Executive Summary")

col1, col2, col3, col4 = st.columns(4)

# Total AUM
aum_query = "SELECT SUM(ABS(NET_INVESTMENT)) as total_aum FROM MART_CUSTOMER_PORTFOLIO"
aum_data = run_query(aum_query)

with col1:
    if not aum_data.empty:
        st.metric("Total AUM", f"${aum_data['TOTAL_AUM'].iloc[0]:,.0f}")

# Customer count
customers_query = "SELECT COUNT(*) as customer_count FROM MART_CUSTOMER_PORTFOLIO"
customers_data = run_query(customers_query)

with col2:
    if not customers_data.empty:
        st.metric("Total Customers", f"{customers_data['CUSTOMER_COUNT'].iloc[0]:,}")

# Average portfolio
avg_query = "SELECT AVG(ABS(NET_INVESTMENT)) as avg_portfolio FROM MART_CUSTOMER_PORTFOLIO"
avg_data = run_query(avg_query)

with col3:
    if not avg_data.empty:
        st.metric("Avg Portfolio", f"${avg_data['AVG_PORTFOLIO'].iloc[0]:,.0f}")

# Total transactions
txn_query = "SELECT SUM(TOTAL_TRANSACTIONS) as total_txns FROM MART_CUSTOMER_PORTFOLIO"
txn_data = run_query(txn_query)

with col4:
    if not txn_data.empty:
        st.metric("Total Transactions", f"{txn_data['TOTAL_TXNS'].iloc[0]:,}")

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
GROUP BY CUSTOMER_TYPE, RISK_LEVEL
ORDER BY total_aum DESC
"""

segmentation_data = run_query(segmentation_query)

if not segmentation_data.empty:
    col1, col2 = st.columns(2)
    
    with col1:
        # AUM by customer type
        aum_by_type = segmentation_data.groupby('CUSTOMER_TYPE')['TOTAL_AUM'].sum().reset_index()
        fig_pie = px.pie(
            aum_by_type,
            values='TOTAL_AUM',
            names='CUSTOMER_TYPE',
            title="AUM Distribution by Customer Type"
        )
        st.plotly_chart(fig_pie, use_container_width=True)
    
    with col2:
        # Customer count by risk level
        customers_by_risk = segmentation_data.groupby('RISK_LEVEL')['CUSTOMER_COUNT'].sum().reset_index()
        fig_bar = px.bar(
            customers_by_risk,
            x='RISK_LEVEL',
            y='CUSTOMER_COUNT',
            title="Customer Count by Risk Level",
            color='RISK_LEVEL'
        )
        st.plotly_chart(fig_bar, use_container_width=True)

# Asset Performance
st.header("📈 Asset Performance")

asset_performance_query = """
SELECT 
    ASSET_CATEGORY,
    COUNT(*) as asset_count,
    AVG(AVG_DAILY_RETURN * 100) as avg_return_pct,
    AVG(DAILY_VOLATILITY * 100) as avg_volatility_pct
FROM MART_ASSET_PERFORMANCE
GROUP BY ASSET_CATEGORY
ORDER BY avg_return_pct DESC
"""

asset_data = run_query(asset_performance_query)

if not asset_data.empty:
    fig_scatter = px.scatter(
        asset_data,
        x='AVG_VOLATILITY_PCT',
        y='AVG_RETURN_PCT',
        size='ASSET_COUNT',
        color='ASSET_CATEGORY',
        title="Risk vs Return by Asset Category"
    )
    st.plotly_chart(fig_scatter, use_container_width=True)

# Data tables
st.header("📋 Detailed Data")

col1, col2 = st.columns(2)

with col1:
    st.subheader("Customer Portfolio Summary")
    portfolio_summary_query = """
    SELECT 
        CUSTOMER_TYPE,
        RISK_LEVEL,
        COUNT(*) as customers,
        AVG(ABS(NET_INVESTMENT)) as avg_portfolio,
        AVG(UNIQUE_ASSETS) as avg_assets
    FROM MART_CUSTOMER_PORTFOLIO
    GROUP BY CUSTOMER_TYPE, RISK_LEVEL
    ORDER BY avg_portfolio DESC
    LIMIT 10
    """
    portfolio_summary = run_query(portfolio_summary_query)
    
    if not portfolio_summary.empty:
        st.dataframe(portfolio_summary, use_container_width=True)

with col2:
    st.subheader("Asset Performance Summary")
    asset_summary_query = """
    SELECT 
        ASSET_CATEGORY,
        SECTOR,
        COUNT(*) as assets,
        AVG(AVG_DAILY_RETURN * 100) as avg_return_pct
    FROM MART_ASSET_PERFORMANCE
    WHERE SECTOR IS NOT NULL
    GROUP BY ASSET_CATEGORY, SECTOR
    ORDER BY avg_return_pct DESC
    LIMIT 10
    """
    asset_summary = run_query(asset_summary_query)
    
    if not asset_summary.empty:
        st.dataframe(asset_summary, use_container_width=True)
$$;

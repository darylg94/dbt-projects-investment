-- Deploy Customer 360 Analytics to Streamlit in Snowflake
-- Based on: https://docs.snowflake.com/en/developer-guide/streamlit/getting-started

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

-- Create Streamlit app with inline code
CREATE OR REPLACE STREAMLIT customer_360_analytics
    QUERY_WAREHOUSE = FAR_TRANS_WH
    COMMENT = 'Customer 360 Analytics Dashboard for Investment Platform'
AS
$$
import streamlit as st
import pandas as pd
import altair as alt

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

# Sidebar filters
st.sidebar.header("📋 Filters")

customer_types = st.sidebar.multiselect(
    "Customer Type",
    options=["Premium", "Mass", "Professional"],
    default=["Premium", "Mass", "Professional"]
)

risk_levels = st.sidebar.multiselect(
    "Risk Level", 
    options=["Income", "Balanced", "Growth"],
    default=["Income", "Balanced", "Growth"]
)

# Executive Summary
st.header("📊 Executive Summary")

col1, col2, col3, col4 = st.columns(4)

# Total AUM
aum_query = "SELECT SUM(ABS(NET_INVESTMENT)) as total_aum FROM MART_CUSTOMER_PORTFOLIO WHERE NET_INVESTMENT IS NOT NULL"
aum_data = run_query(aum_query)

with col1:
    if not aum_data.empty and aum_data['TOTAL_AUM'].iloc[0] is not None:
        st.metric("Total AUM", f"${aum_data['TOTAL_AUM'].iloc[0]:,.0f}")
    else:
        st.metric("Total AUM", "No data")

# Customer count
customers_query = "SELECT COUNT(*) as customer_count FROM MART_CUSTOMER_PORTFOLIO"
customers_data = run_query(customers_query)

with col2:
    if not customers_data.empty:
        st.metric("Total Customers", f"{customers_data['CUSTOMER_COUNT'].iloc[0]:,}")

# Average portfolio
avg_query = "SELECT AVG(ABS(NET_INVESTMENT)) as avg_portfolio FROM MART_CUSTOMER_PORTFOLIO WHERE NET_INVESTMENT IS NOT NULL"
avg_data = run_query(avg_query)

with col3:
    if not avg_data.empty and avg_data['AVG_PORTFOLIO'].iloc[0] is not None:
        st.metric("Avg Portfolio", f"${avg_data['AVG_PORTFOLIO'].iloc[0]:,.0f}")
    else:
        st.metric("Avg Portfolio", "No data")

# Total transactions
txn_query = "SELECT SUM(TOTAL_TRANSACTIONS) as total_txns FROM MART_CUSTOMER_PORTFOLIO WHERE TOTAL_TRANSACTIONS IS NOT NULL"
txn_data = run_query(txn_query)

with col4:
    if not txn_data.empty and txn_data['TOTAL_TXNS'].iloc[0] is not None:
        st.metric("Total Transactions", f"{txn_data['TOTAL_TXNS'].iloc[0]:,}")
    else:
        st.metric("Total Transactions", "No data")

# Customer Segmentation
st.header("👥 Customer Segmentation")

# Create filter conditions
customer_filter = f"CUSTOMER_TYPE IN ({','.join([f\"'{ct}'\" for ct in customer_types])})"
risk_filter = f"RISK_LEVEL IN ({','.join([f\"'{rl}'\" for rl in risk_levels])})"

segmentation_query = f"""
SELECT 
    CUSTOMER_TYPE,
    RISK_LEVEL,
    COUNT(*) as customer_count,
    AVG(ABS(NET_INVESTMENT)) as avg_portfolio_size,
    SUM(ABS(NET_INVESTMENT)) as total_aum
FROM MART_CUSTOMER_PORTFOLIO
WHERE {customer_filter} AND {risk_filter} AND NET_INVESTMENT IS NOT NULL
GROUP BY CUSTOMER_TYPE, RISK_LEVEL
ORDER BY total_aum DESC
"""

segmentation_data = run_query(segmentation_query)

if not segmentation_data.empty:
    col1, col2 = st.columns(2)
    
    with col1:
        # AUM by customer type - Altair pie chart
        aum_by_type = segmentation_data.groupby('CUSTOMER_TYPE')['TOTAL_AUM'].sum().reset_index()
        fig_pie = alt.Chart(aum_by_type).mark_arc().encode(
            theta=alt.Theta(field="TOTAL_AUM", type="quantitative"),
            color=alt.Color(field="CUSTOMER_TYPE", type="nominal"),
            tooltip=['CUSTOMER_TYPE', 'TOTAL_AUM']
        ).properties(
            title="AUM Distribution by Customer Type",
            width=300,
            height=300
        )
        st.altair_chart(fig_pie, use_container_width=True)
    
    with col2:
        # Customer count by risk level - Altair bar chart
        customers_by_risk = segmentation_data.groupby('RISK_LEVEL')['CUSTOMER_COUNT'].sum().reset_index()
        fig_bar = alt.Chart(customers_by_risk).mark_bar().encode(
            x=alt.X('RISK_LEVEL:N', title='Risk Level'),
            y=alt.Y('CUSTOMER_COUNT:Q', title='Customer Count'),
            color=alt.Color('RISK_LEVEL:N', scale=alt.Scale(scheme='category10')),
            tooltip=['RISK_LEVEL', 'CUSTOMER_COUNT']
        ).properties(
            title="Customer Count by Risk Level",
            width=300,
            height=300
        )
        st.altair_chart(fig_bar, use_container_width=True)

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
    # Risk vs Return scatter plot
    fig_scatter = alt.Chart(asset_data).mark_circle(size=200).encode(
        x=alt.X('AVG_VOLATILITY_PCT:Q', title='Average Volatility (%)'),
        y=alt.Y('AVG_RETURN_PCT:Q', title='Average Return (%)'),
        color=alt.Color('ASSET_CATEGORY:N', title='Asset Category'),
        size=alt.Size('ASSET_COUNT:Q', title='Asset Count'),
        tooltip=['ASSET_CATEGORY', 'ASSET_COUNT', 'AVG_RETURN_PCT', 'AVG_VOLATILITY_PCT']
    ).properties(
        title="Risk vs Return by Asset Category",
        width=600,
        height=400
    )
    st.altair_chart(fig_scatter, use_container_width=True)

# Portfolio Analysis
st.header("💼 Portfolio Analysis")

portfolio_analysis_query = f"""
SELECT 
    CUSTOMER_TYPE,
    RISK_LEVEL,
    COUNT(*) as customers,
    AVG(ABS(NET_INVESTMENT)) as avg_portfolio_value,
    AVG(UNIQUE_ASSETS) as avg_diversification,
    AVG(TOTAL_TRANSACTIONS) as avg_activity
FROM MART_CUSTOMER_PORTFOLIO
WHERE {customer_filter} AND {risk_filter}
GROUP BY CUSTOMER_TYPE, RISK_LEVEL
ORDER BY avg_portfolio_value DESC
"""

portfolio_analysis = run_query(portfolio_analysis_query)

if not portfolio_analysis.empty:
    # Heatmap using Altair
    fig_heatmap = alt.Chart(portfolio_analysis).mark_rect().encode(
        x=alt.X('RISK_LEVEL:N', title='Risk Level'),
        y=alt.Y('CUSTOMER_TYPE:N', title='Customer Type'),
        color=alt.Color('AVG_PORTFOLIO_VALUE:Q', scale=alt.Scale(scheme='blues'), title='Avg Portfolio Value'),
        tooltip=['CUSTOMER_TYPE', 'RISK_LEVEL', 'CUSTOMERS', 'AVG_PORTFOLIO_VALUE', 'AVG_DIVERSIFICATION']
    ).properties(
        title="Portfolio Value Heatmap by Customer Type & Risk Level",
        width=400,
        height=200
    )
    st.altair_chart(fig_heatmap, use_container_width=True)

# Data Tables
st.header("📋 Detailed Analytics")

col1, col2 = st.columns(2)

with col1:
    st.subheader("Top Customer Portfolios")
    top_customers_query = f"""
    SELECT 
        CUSTOMER_TYPE,
        RISK_LEVEL,
        ABS(NET_INVESTMENT) as portfolio_value,
        TOTAL_TRANSACTIONS,
        UNIQUE_ASSETS
    FROM MART_CUSTOMER_PORTFOLIO
    WHERE {customer_filter} AND {risk_filter} AND NET_INVESTMENT IS NOT NULL
    ORDER BY portfolio_value DESC
    LIMIT 10
    """
    top_customers = run_query(top_customers_query)
    
    if not top_customers.empty:
        # Format currency
        formatted_customers = top_customers.copy()
        formatted_customers['PORTFOLIO_VALUE'] = formatted_customers['PORTFOLIO_VALUE'].apply(
            lambda x: f"${x:,.0f}" if pd.notna(x) else "N/A"
        )
        st.dataframe(formatted_customers, use_container_width=True)

with col2:
    st.subheader("Asset Performance Summary")
    asset_summary_query = """
    SELECT 
        ASSET_CATEGORY,
        COUNT(*) as asset_count,
        AVG(COALESCE(AVG_DAILY_RETURN, 0) * 100) as avg_return_pct,
        AVG(COALESCE(DAILY_VOLATILITY, 0) * 100) as avg_volatility_pct
    FROM MART_ASSET_PERFORMANCE
    GROUP BY ASSET_CATEGORY
    ORDER BY avg_return_pct DESC
    """
    asset_summary = run_query(asset_summary_query)
    
    if not asset_summary.empty:
        # Format percentages
        formatted_assets = asset_summary.copy()
        formatted_assets['AVG_RETURN_PCT'] = formatted_assets['AVG_RETURN_PCT'].apply(
            lambda x: f"{x:.4f}%" if pd.notna(x) else "N/A"
        )
        formatted_assets['AVG_VOLATILITY_PCT'] = formatted_assets['AVG_VOLATILITY_PCT'].apply(
            lambda x: f"{x:.4f}%" if pd.notna(x) else "N/A"
        )
        st.dataframe(formatted_assets, use_container_width=True)

$$;

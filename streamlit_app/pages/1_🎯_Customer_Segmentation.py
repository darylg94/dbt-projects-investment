import streamlit as st
import pandas as pd
import altair as alt

st.set_page_config(page_title="Customer Segmentation", page_icon="🎯", layout="wide")

# Get Snowflake session - native SIS connection
@st.cache_resource
def get_session():
    return st.connection('snowflake').session()

# Query execution function using Snowflake session
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
        st.error(f"Error executing query: {e}")
        return pd.DataFrame()

# Initialize database context
def init_database_context():
    session = get_session()
    session.sql("USE DATABASE FAR_TRANS_DB").collect()
    session.sql("USE SCHEMA MARTS").collect()
    session.sql("USE WAREHOUSE FAR_TRANS_WH").collect()

# Initialize context
init_database_context()

st.title("🎯 Customer Segmentation Analysis")

# Sidebar filters
st.sidebar.header("Filters")
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

# Create filter conditions
customer_filter = f"CUSTOMER_TYPE IN ({','.join([f\"'{ct}'\" for ct in customer_types])})"
risk_filter = f"RISK_LEVEL IN ({','.join([f\"'{rl}'\" for rl in risk_levels])})"

# Customer Segmentation Matrix
st.header("📊 Customer Segmentation Matrix")

segmentation_query = f"""
SELECT 
    CUSTOMER_TYPE,
    RISK_LEVEL,
    COUNT(*) as customer_count,
    AVG(ABS(NET_INVESTMENT)) as avg_portfolio_size,
    SUM(ABS(NET_INVESTMENT)) as total_aum,
    AVG(TOTAL_TRANSACTIONS) as avg_transaction_frequency,
    AVG(UNIQUE_ASSETS) as avg_diversification
FROM MART_CUSTOMER_PORTFOLIO
WHERE {customer_filter} AND {risk_filter}
GROUP BY CUSTOMER_TYPE, RISK_LEVEL
ORDER BY total_aum DESC
"""

segmentation_data = run_query(segmentation_query)

if not segmentation_data.empty:
    col1, col2 = st.columns(2)
    
    with col1:
        # Customer count heatmap
        fig_heatmap = alt.Chart(segmentation_data).mark_rect().encode(
            x=alt.X('RISK_LEVEL:N', title='Risk Level'),
            y=alt.Y('CUSTOMER_TYPE:N', title='Customer Type'),
            color=alt.Color('TOTAL_AUM:Q', scale=alt.Scale(scheme='blues'), title='Total AUM'),
            tooltip=['CUSTOMER_TYPE', 'RISK_LEVEL', 'CUSTOMER_COUNT', 'TOTAL_AUM']
        ).properties(
            title="AUM Heatmap by Customer Type & Risk Level",
            width=300,
            height=200
        )
        st.altair_chart(fig_heatmap, use_container_width=True)
    
    with col2:
        # Bubble chart for segmentation
        fig_bubble = alt.Chart(segmentation_data).mark_circle().encode(
            x=alt.X('AVG_PORTFOLIO_SIZE:Q', title='Average Portfolio Size'),
            y=alt.Y('CUSTOMER_COUNT:Q', title='Customer Count'),
            size=alt.Size('TOTAL_AUM:Q', title='Total AUM'),
            color=alt.Color('RISK_LEVEL:N', title='Risk Level'),
            shape=alt.Shape('CUSTOMER_TYPE:N', title='Customer Type'),
            tooltip=['CUSTOMER_TYPE', 'RISK_LEVEL', 'CUSTOMER_COUNT', 'AVG_PORTFOLIO_SIZE', 'TOTAL_AUM']
        ).properties(
            title="Customer Segmentation Bubble Chart",
            width=400,
            height=300
        )
        st.altair_chart(fig_bubble, use_container_width=True)

# Detailed segmentation table
st.header("📋 Detailed Segmentation Data")
if not segmentation_data.empty:
    # Format currency columns
    formatted_data = segmentation_data.copy()
    formatted_data['AVG_PORTFOLIO_SIZE'] = formatted_data['AVG_PORTFOLIO_SIZE'].apply(
        lambda x: f"${x:,.0f}" if pd.notna(x) else "N/A"
    )
    formatted_data['TOTAL_AUM'] = formatted_data['TOTAL_AUM'].apply(
        lambda x: f"${x:,.0f}" if pd.notna(x) else "N/A"
    )
    formatted_data['AVG_TRANSACTION_FREQUENCY'] = formatted_data['AVG_TRANSACTION_FREQUENCY'].apply(
        lambda x: f"{x:.1f}" if pd.notna(x) else "N/A"
    )
    formatted_data['AVG_DIVERSIFICATION'] = formatted_data['AVG_DIVERSIFICATION'].apply(
        lambda x: f"{x:.1f}" if pd.notna(x) else "N/A"
    )
    st.dataframe(formatted_data, use_container_width=True)

# Customer Lifecycle Analysis
st.header("📈 Customer Lifecycle Analysis")

lifecycle_query = f"""
SELECT 
    CASE 
        WHEN ABS(NET_INVESTMENT) >= 100000 THEN 'High Value'
        WHEN ABS(NET_INVESTMENT) >= 50000 THEN 'Medium Value'
        WHEN ABS(NET_INVESTMENT) >= 10000 THEN 'Low Value'
        ELSE 'Minimal Value'
    END as value_segment,
    CASE 
        WHEN TOTAL_TRANSACTIONS >= 50 THEN 'High Activity'
        WHEN TOTAL_TRANSACTIONS >= 20 THEN 'Medium Activity'
        WHEN TOTAL_TRANSACTIONS >= 5 THEN 'Low Activity'
        ELSE 'Minimal Activity'
    END as activity_level,
    COUNT(*) as customer_count,
    AVG(ABS(NET_INVESTMENT)) as avg_portfolio_value,
    AVG(UNIQUE_ASSETS) as avg_diversification
FROM MART_CUSTOMER_PORTFOLIO
WHERE {customer_filter} AND {risk_filter}
GROUP BY value_segment, activity_level
ORDER BY avg_portfolio_value DESC
"""

lifecycle_data = run_query(lifecycle_query)

if not lifecycle_data.empty:
    # Altair grouped bar chart
    fig_grouped = alt.Chart(lifecycle_data).mark_bar().encode(
        x=alt.X('VALUE_SEGMENT:N', title='Value Segment'),
        y=alt.Y('CUSTOMER_COUNT:Q', title='Customer Count'),
        color=alt.Color('ACTIVITY_LEVEL:N', title='Activity Level'),
        column=alt.Column('ACTIVITY_LEVEL:N', title='Activity Level'),
        tooltip=['VALUE_SEGMENT', 'ACTIVITY_LEVEL', 'CUSTOMER_COUNT', 'AVG_PORTFOLIO_VALUE']
    ).properties(
        title="Customer Distribution by Value & Activity",
        width=150,
        height=200
    )
    st.altair_chart(fig_grouped, use_container_width=True)

# Risk Profile Analysis
st.header("⚖️ Risk Profile Analysis")

risk_profile_query = f"""
SELECT 
    RISK_LEVEL,
    CUSTOMER_TYPE,
    COUNT(*) as customers,
    AVG(ABS(NET_INVESTMENT)) as avg_portfolio,
    AVG(UNIQUE_ASSETS) as avg_diversification,
    AVG(ASSET_CATEGORIES_TRADED) as avg_categories
FROM MART_CUSTOMER_PORTFOLIO
WHERE {customer_filter} AND {risk_filter}
GROUP BY RISK_LEVEL, CUSTOMER_TYPE
ORDER BY avg_portfolio DESC
"""

risk_profile_data = run_query(risk_profile_query)

if not risk_profile_data.empty:
    col1, col2 = st.columns(2)
    
    with col1:
        # Risk vs Portfolio Size
        fig_risk_portfolio = alt.Chart(risk_profile_data).mark_bar().encode(
            x=alt.X('RISK_LEVEL:N', title='Risk Level'),
            y=alt.Y('AVG_PORTFOLIO:Q', title='Average Portfolio Value'),
            color=alt.Color('CUSTOMER_TYPE:N', title='Customer Type'),
            column=alt.Column('CUSTOMER_TYPE:N'),
            tooltip=['RISK_LEVEL', 'CUSTOMER_TYPE', 'AVG_PORTFOLIO', 'CUSTOMERS']
        ).properties(
            title="Portfolio Size by Risk & Customer Type",
            width=150,
            height=200
        )
        st.altair_chart(fig_risk_portfolio, use_container_width=True)
    
    with col2:
        # Risk vs Diversification
        fig_risk_div = alt.Chart(risk_profile_data).mark_circle(size=100).encode(
            x=alt.X('AVG_DIVERSIFICATION:Q', title='Average Diversification'),
            y=alt.Y('AVG_PORTFOLIO:Q', title='Average Portfolio Value'),
            color=alt.Color('RISK_LEVEL:N', title='Risk Level'),
            size=alt.Size('CUSTOMERS:Q', title='Customer Count'),
            tooltip=['RISK_LEVEL', 'CUSTOMER_TYPE', 'AVG_PORTFOLIO', 'AVG_DIVERSIFICATION', 'CUSTOMERS']
        ).properties(
            title="Portfolio Value vs Diversification by Risk Level",
            width=400,
            height=300
        )
        st.altair_chart(fig_risk_div, use_container_width=True)

# Investment Capacity Analysis
st.header("💰 Investment Capacity Analysis")

capacity_analysis_query = f"""
SELECT 
    INVESTMENT_CAPACITY,
    RISK_LEVEL,
    COUNT(*) as customer_count,
    AVG(ABS(NET_INVESTMENT)) as avg_portfolio_value,
    AVG(TOTAL_TRANSACTIONS) as avg_transactions
FROM MART_CUSTOMER_PORTFOLIO
WHERE {customer_filter} AND {risk_filter}
GROUP BY INVESTMENT_CAPACITY, RISK_LEVEL
ORDER BY avg_portfolio_value DESC
"""

capacity_analysis = run_query(capacity_analysis_query)

if not capacity_analysis.empty:
    # Stacked bar chart for investment capacity
    fig_capacity = alt.Chart(capacity_analysis).mark_bar().encode(
        x=alt.X('INVESTMENT_CAPACITY:N', title='Investment Capacity', sort='-y'),
        y=alt.Y('AVG_PORTFOLIO_VALUE:Q', title='Average Portfolio Value'),
        color=alt.Color('RISK_LEVEL:N', title='Risk Level'),
        tooltip=['INVESTMENT_CAPACITY', 'RISK_LEVEL', 'CUSTOMER_COUNT', 'AVG_PORTFOLIO_VALUE']
    ).properties(
        title="Portfolio Value by Investment Capacity & Risk Level",
        width=600,
        height=400
    )
    st.altair_chart(fig_capacity, use_container_width=True)
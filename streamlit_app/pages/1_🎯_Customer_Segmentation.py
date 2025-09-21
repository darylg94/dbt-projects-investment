import streamlit as st
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go

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
    # Create 2x2 subplot layout
    col1, col2 = st.columns(2)
    
    with col1:
        # Heatmap for AUM
        pivot_aum = segmentation_data.pivot(
            index='CUSTOMER_TYPE', 
            columns='RISK_LEVEL', 
            values='TOTAL_AUM'
        ).fillna(0)
        
        fig_heatmap = px.imshow(
            pivot_aum,
            title="Total AUM by Customer Type & Risk Level",
            labels=dict(x="Risk Level", y="Customer Type", color="Total AUM"),
            aspect="auto",
            color_continuous_scale="Blues"
        )
        st.plotly_chart(fig_heatmap, use_container_width=True)
    
    with col2:
        # Bubble chart for customer count vs portfolio size
        fig_bubble = px.scatter(
            segmentation_data,
            x='AVG_PORTFOLIO_SIZE',
            y='CUSTOMER_COUNT',
            size='TOTAL_AUM',
            color='RISK_LEVEL',
            hover_data=['CUSTOMER_TYPE', 'AVG_TRANSACTION_FREQUENCY'],
            title="Customer Count vs Average Portfolio Size"
        )
        st.plotly_chart(fig_bubble, use_container_width=True)

# Detailed segmentation table
st.header("📋 Detailed Segmentation Data")
if not segmentation_data.empty:
    st.dataframe(
        segmentation_data.style.format({
            'AVG_PORTFOLIO_SIZE': '${:,.0f}',
            'TOTAL_AUM': '${:,.0f}',
            'AVG_TRANSACTION_FREQUENCY': '{:.1f}',
            'AVG_DIVERSIFICATION': '{:.1f}'
        }),
        use_container_width=True
    )

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
    fig_treemap = px.treemap(
        lifecycle_data,
        path=['VALUE_SEGMENT', 'ACTIVITY_LEVEL'],
        values='CUSTOMER_COUNT',
        color='AVG_PORTFOLIO_VALUE',
        title="Customer Distribution by Value Segment & Activity Level",
        color_continuous_scale="RdYlBu"
    )
    st.plotly_chart(fig_treemap, use_container_width=True)

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
        fig_risk_portfolio = px.bar(
            risk_profile_data,
            x='RISK_LEVEL',
            y='AVG_PORTFOLIO',
            color='CUSTOMER_TYPE',
            title="Average Portfolio Size by Risk Level & Customer Type",
            barmode='group'
        )
        st.plotly_chart(fig_risk_portfolio, use_container_width=True)
    
    with col2:
        # Risk vs Diversification
        fig_risk_div = px.bar(
            risk_profile_data,
            x='RISK_LEVEL',
            y='AVG_DIVERSIFICATION',
            color='CUSTOMER_TYPE',
            title="Average Diversification by Risk Level & Customer Type",
            barmode='group'
        )
        st.plotly_chart(fig_risk_div, use_container_width=True)
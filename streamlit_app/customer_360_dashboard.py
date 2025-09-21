import streamlit as st
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
from plotly.subplots import make_subplots
import numpy as np
from datetime import datetime, timedelta

# Page configuration
st.set_page_config(
    page_title="Customer 360 Analytics Dashboard",
    page_icon="📊",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Custom CSS for better styling
st.markdown("""
<style>
    .main-header {
        font-size: 2.5rem;
        color: #1f77b4;
        text-align: center;
        margin-bottom: 2rem;
    }
    .metric-card {
        background-color: #f0f2f6;
        padding: 1rem;
        border-radius: 0.5rem;
        margin: 0.5rem 0;
    }
    .sidebar .sidebar-content {
        background-color: #f8f9fa;
    }
</style>
""", unsafe_allow_html=True)

# Get Snowflake session - native SIS connection
@st.cache_resource
def get_session():
    return st.connection('snowflake').session()

# Query execution function using Snowflake session
@st.cache_data(ttl=600)  # Cache for 10 minutes
def run_query(query):
    try:
        session = get_session()
        result = session.sql(query).collect()
        # Convert to pandas DataFrame
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

# Main dashboard
def main():
    # Initialize database context
    init_database_context()
    
    st.markdown('<h1 class="main-header">🏦 Customer 360 Analytics Dashboard</h1>', unsafe_allow_html=True)
    
    # Sidebar filters
    st.sidebar.header("📋 Filters")
    
    # Date range filter
    date_range = st.sidebar.date_input(
        "Select Date Range",
        value=(datetime.now() - timedelta(days=365), datetime.now()),
        key="date_range"
    )
    
    # Customer type filter
    customer_types = st.sidebar.multiselect(
        "Customer Type",
        options=["Premium", "Mass", "Professional"],
        default=["Premium", "Mass", "Professional"]
    )
    
    # Risk level filter
    risk_levels = st.sidebar.multiselect(
        "Risk Level",
        options=["Income", "Balanced", "Growth"],
        default=["Income", "Balanced", "Growth"]
    )
    
    # Asset category filter
    asset_categories = st.sidebar.multiselect(
        "Asset Category",
        options=["Stock", "Bond", "MTF"],
        default=["Stock", "Bond", "MTF"]
    )
    
    # Create filter conditions
    customer_filter = f"customer_type IN ({','.join([f\"'{ct}'\" for ct in customer_types])})"
    risk_filter = f"risk_level IN ({','.join([f\"'{rl}'\" for rl in risk_levels])})"
    asset_filter = f"asset_category IN ({','.join([f\"'{ac}'\" for ac in asset_categories])})"
    date_filter = f"transaction_date BETWEEN '{date_range[0]}' AND '{date_range[1]}'"
    
    # Main dashboard tabs
    tab1, tab2, tab3, tab4, tab5 = st.tabs([
        "📊 Executive Summary", 
        "👥 Customer Analytics", 
        "💼 Portfolio Analysis", 
        "📈 Asset Performance", 
        "🔄 Transaction Analysis"
    ])
    
    with tab1:
        show_executive_summary(customer_filter, risk_filter, asset_filter, date_filter)
    
    with tab2:
        show_customer_analytics(customer_filter, risk_filter, date_filter)
    
    with tab3:
        show_portfolio_analysis(customer_filter, risk_filter, asset_filter)
    
    with tab4:
        show_asset_performance(asset_filter, date_filter)
    
    with tab5:
        show_transaction_analysis(customer_filter, asset_filter, date_filter)

def show_executive_summary(customer_filter, risk_filter, asset_filter, date_filter):
    st.header("📊 Executive Summary")
    
    # KPI Metrics
    col1, col2, col3, col4 = st.columns(4)
    
    # Total AUM
    aum_query = f"""
    SELECT SUM(NET_INVESTMENT) as total_aum
    FROM MART_CUSTOMER_PORTFOLIO
    WHERE CUSTOMER_TYPE IN ('Premium', 'Mass', 'Professional')
    """
    aum_data = run_query(aum_query)
    
    with col1:
        if not aum_data.empty:
            st.metric("Total AUM", f"${aum_data['TOTAL_AUM'].iloc[0]:,.0f}")
    
    # Active Customers
    customers_query = f"""
    SELECT COUNT(DISTINCT CUSTOMER_ID) as active_customers
    FROM MART_CUSTOMER_PORTFOLIO
    """
    customers_data = run_query(customers_query)
    
    with col2:
        if not customers_data.empty:
            st.metric("Active Customers", f"{customers_data['ACTIVE_CUSTOMERS'].iloc[0]:,}")
    
    # Average Portfolio Size
    avg_portfolio_query = f"""
    SELECT AVG(ABS(NET_INVESTMENT)) as avg_portfolio
    FROM MART_CUSTOMER_PORTFOLIO
    """
    avg_portfolio_data = run_query(avg_portfolio_query)
    
    with col3:
        if not avg_portfolio_data.empty:
            st.metric("Avg Portfolio Size", f"${avg_portfolio_data['AVG_PORTFOLIO'].iloc[0]:,.0f}")
    
    # Total Transactions
    transactions_query = f"""
    SELECT SUM(TOTAL_TRANSACTIONS) as total_txns
    FROM MART_CUSTOMER_PORTFOLIO
    """
    transactions_data = run_query(transactions_query)
    
    with col4:
        if not transactions_data.empty:
            st.metric("Total Transactions", f"{transactions_data['TOTAL_TXNS'].iloc[0]:,}")
    
    # AUM by Customer Type (Pie Chart)
    col1, col2 = st.columns(2)
    
    with col1:
        st.subheader("AUM Distribution by Customer Type")
        aum_by_type_query = f"""
        SELECT 
            CUSTOMER_TYPE,
            SUM(ABS(NET_INVESTMENT)) as total_aum
        FROM MART_CUSTOMER_PORTFOLIO
        GROUP BY CUSTOMER_TYPE
        ORDER BY total_aum DESC
        """
        aum_by_type = run_query(aum_by_type_query)
        
        if not aum_by_type.empty:
            fig_pie = px.pie(
                aum_by_type, 
                values='TOTAL_AUM', 
                names='CUSTOMER_TYPE',
                title="AUM Distribution"
            )
            st.plotly_chart(fig_pie, use_container_width=True)
    
    with col2:
        st.subheader("Customer Count by Risk Level")
        customers_by_risk_query = f"""
        SELECT 
            RISK_LEVEL,
            COUNT(*) as customer_count
        FROM MART_CUSTOMER_PORTFOLIO
        GROUP BY RISK_LEVEL
        ORDER BY customer_count DESC
        """
        customers_by_risk = run_query(customers_by_risk_query)
        
        if not customers_by_risk.empty:
            fig_bar = px.bar(
                customers_by_risk,
                x='RISK_LEVEL',
                y='CUSTOMER_COUNT',
                title="Customers by Risk Level",
                color='RISK_LEVEL'
            )
            st.plotly_chart(fig_bar, use_container_width=True)

def show_customer_analytics(customer_filter, risk_filter, date_filter):
    st.header("👥 Customer Analytics")
    
    # Customer Segmentation Matrix
    st.subheader("Customer Segmentation Matrix")
    segmentation_query = f"""
    SELECT 
        CUSTOMER_TYPE,
        RISK_LEVEL,
        COUNT(*) as customer_count,
        AVG(ABS(NET_INVESTMENT)) as avg_portfolio_size,
        SUM(ABS(NET_INVESTMENT)) as total_aum,
        AVG(TOTAL_TRANSACTIONS) as avg_transaction_frequency
    FROM MART_CUSTOMER_PORTFOLIO
    GROUP BY CUSTOMER_TYPE, RISK_LEVEL
    ORDER BY total_aum DESC
    """
    segmentation_data = run_query(segmentation_query)
    
    if not segmentation_data.empty:
        # Heatmap for customer segmentation
        pivot_data = segmentation_data.pivot(
            index='CUSTOMER_TYPE', 
            columns='RISK_LEVEL', 
            values='TOTAL_AUM'
        ).fillna(0)
        
        fig_heatmap = px.imshow(
            pivot_data,
            title="AUM Heatmap by Customer Type & Risk Level",
            labels=dict(x="Risk Level", y="Customer Type", color="Total AUM"),
            aspect="auto"
        )
        st.plotly_chart(fig_heatmap, use_container_width=True)
        
        # Data table
        st.subheader("Customer Segmentation Details")
        st.dataframe(segmentation_data, use_container_width=True)

def show_portfolio_analysis(customer_filter, risk_filter, asset_filter):
    st.header("💼 Portfolio Analysis")
    
    # Portfolio Diversification Analysis
    col1, col2 = st.columns(2)
    
    with col1:
        st.subheader("Portfolio Diversification")
        diversification_query = f"""
        SELECT 
            CASE 
                WHEN UNIQUE_ASSETS >= 10 THEN 'Well Diversified (10+)'
                WHEN UNIQUE_ASSETS >= 5 THEN 'Moderately Diversified (5-9)'
                WHEN UNIQUE_ASSETS >= 2 THEN 'Limited Diversification (2-4)'
                ELSE 'Single Asset (1)'
            END as diversification_level,
            COUNT(*) as customer_count,
            AVG(ABS(NET_INVESTMENT)) as avg_portfolio_value,
            AVG(UNIQUE_ASSETS) as avg_assets
        FROM MART_CUSTOMER_PORTFOLIO
        GROUP BY diversification_level
        ORDER BY avg_assets DESC
        """
        diversification_data = run_query(diversification_query)
        
        if not diversification_data.empty:
            fig_scatter = px.scatter(
                diversification_data,
                x='AVG_ASSETS',
                y='AVG_PORTFOLIO_VALUE',
                size='CUSTOMER_COUNT',
                color='DIVERSIFICATION_LEVEL',
                title="Diversification vs Portfolio Value",
                hover_data=['CUSTOMER_COUNT']
            )
            st.plotly_chart(fig_scatter, use_container_width=True)
    
    with col2:
        st.subheader("Investment Capacity Analysis")
        capacity_query = f"""
        SELECT 
            INVESTMENT_CAPACITY,
            COUNT(*) as customer_count,
            AVG(ABS(NET_INVESTMENT)) as avg_portfolio_value,
            AVG(TOTAL_TRANSACTIONS) as avg_activity
        FROM MART_CUSTOMER_PORTFOLIO
        GROUP BY INVESTMENT_CAPACITY
        ORDER BY avg_portfolio_value DESC
        """
        capacity_data = run_query(capacity_query)
        
        if not capacity_data.empty:
            fig_bar = px.bar(
                capacity_data,
                x='INVESTMENT_CAPACITY',
                y='AVG_PORTFOLIO_VALUE',
                color='CUSTOMER_COUNT',
                title="Portfolio Value by Investment Capacity",
                color_continuous_scale='Viridis'
            )
            fig_bar.update_xaxes(tickangle=45)
            st.plotly_chart(fig_bar, use_container_width=True)

def show_asset_performance(asset_filter, date_filter):
    st.header("📈 Asset Performance")
    
    # Asset Performance Metrics
    col1, col2, col3 = st.columns(3)
    
    # Top performing assets
    with col1:
        st.subheader("Top Performing Assets")
        top_assets_query = f"""
        SELECT 
            ASSET_NAME,
            ASSET_CATEGORY,
            SECTOR,
            (AVG_DAILY_RETURN * 100) as avg_daily_return_pct,
            (DAILY_VOLATILITY * 100) as daily_volatility_pct,
            CASE 
                WHEN DAILY_VOLATILITY > 0 
                THEN AVG_DAILY_RETURN / DAILY_VOLATILITY 
                ELSE NULL 
            END as sharpe_ratio
        FROM MART_ASSET_PERFORMANCE
        WHERE ASSET_CATEGORY IN ('Stock', 'Bond', 'MTF')
        ORDER BY AVG_DAILY_RETURN DESC
        LIMIT 10
        """
        top_assets = run_query(top_assets_query)
        
        if not top_assets.empty:
            fig_bar = px.bar(
                top_assets,
                x='AVG_DAILY_RETURN_PCT',
                y='ASSET_NAME',
                color='ASSET_CATEGORY',
                title="Top 10 Assets by Daily Return",
                orientation='h'
            )
            fig_bar.update_layout(height=500)
            st.plotly_chart(fig_bar, use_container_width=True)
    
    # Sector Performance
    with col2:
        st.subheader("Sector Performance")
        sector_performance_query = f"""
        SELECT 
            SECTOR,
            COUNT(*) as asset_count,
            AVG(AVG_DAILY_RETURN * 100) as sector_avg_return,
            AVG(DAILY_VOLATILITY * 100) as sector_avg_risk
        FROM MART_ASSET_PERFORMANCE
        WHERE SECTOR IS NOT NULL
        GROUP BY SECTOR
        ORDER BY sector_avg_return DESC
        """
        sector_performance = run_query(sector_performance_query)
        
        if not sector_performance.empty:
            fig_scatter = px.scatter(
                sector_performance,
                x='SECTOR_AVG_RISK',
                y='SECTOR_AVG_RETURN',
                size='ASSET_COUNT',
                color='SECTOR',
                title="Risk vs Return by Sector",
                hover_data=['ASSET_COUNT']
            )
            st.plotly_chart(fig_scatter, use_container_width=True)
    
    # Risk Categories
    with col3:
        st.subheader("Risk Distribution")
        risk_dist_query = f"""
        SELECT 
            CASE 
                WHEN DAILY_VOLATILITY < 0.01 THEN 'Low Risk'
                WHEN DAILY_VOLATILITY < 0.02 THEN 'Medium Risk'
                ELSE 'High Risk'
            END as risk_category,
            COUNT(*) as asset_count,
            AVG(AVG_DAILY_RETURN * 100) as avg_return
        FROM MART_ASSET_PERFORMANCE
        GROUP BY risk_category
        ORDER BY avg_return DESC
        """
        risk_dist = run_query(risk_dist_query)
        
        if not risk_dist.empty:
            fig_pie = px.pie(
                risk_dist,
                values='ASSET_COUNT',
                names='RISK_CATEGORY',
                title="Asset Distribution by Risk Category"
            )
            st.plotly_chart(fig_pie, use_container_width=True)

def show_transaction_analysis(customer_filter, asset_filter, date_filter):
    st.header("🔄 Transaction Analysis")
    
    # Monthly Transaction Trends using INT_CUSTOMER_TRANSACTIONS
    st.subheader("Monthly Transaction Trends")
    monthly_trends_query = f"""
    SELECT 
        TO_CHAR(TRANSACTION_DATE, 'YYYY-MM') as transaction_month,
        CUSTOMER_TYPE,
        SUM(CASE WHEN TRANSACTION_TYPE = 'Buy' THEN TOTAL_VALUE ELSE -TOTAL_VALUE END) as monthly_net_flow,
        COUNT(DISTINCT CUSTOMER_ID) as active_customers,
        AVG(TOTAL_VALUE) as avg_transaction_size,
        COUNT(*) as total_transactions
    FROM INT_CUSTOMER_TRANSACTIONS
    WHERE TRANSACTION_DATE >= DATEADD('month', -12, CURRENT_DATE())
    GROUP BY transaction_month, CUSTOMER_TYPE
    ORDER BY transaction_month, CUSTOMER_TYPE
    """
    monthly_trends = run_query(monthly_trends_query)
    
    if not monthly_trends.empty:
        fig_line = px.line(
            monthly_trends,
            x='TRANSACTION_MONTH',
            y='MONTHLY_NET_FLOW',
            color='CUSTOMER_TYPE',
            title="Monthly Net Investment Flow by Customer Type",
            markers=True
        )
        st.plotly_chart(fig_line, use_container_width=True)
    
    # Channel Performance Analysis
    col1, col2 = st.columns(2)
    
    with col1:
        st.subheader("Channel Performance")
        channel_performance_query = f"""
        SELECT 
            CHANNEL,
            ASSET_CATEGORY,
            COUNT(*) as transaction_count,
            SUM(TOTAL_VALUE) as channel_volume,
            COUNT(DISTINCT CUSTOMER_ID) as unique_customers
        FROM INT_CUSTOMER_TRANSACTIONS
        GROUP BY CHANNEL, ASSET_CATEGORY
        ORDER BY channel_volume DESC
        """
        channel_performance = run_query(channel_performance_query)
        
        if not channel_performance.empty:
            fig_stacked = px.bar(
                channel_performance,
                x='CHANNEL',
                y='CHANNEL_VOLUME',
                color='ASSET_CATEGORY',
                title="Transaction Volume by Channel & Asset Category",
                barmode='stack'
            )
            st.plotly_chart(fig_stacked, use_container_width=True)
    
    with col2:
        st.subheader("Transaction Size Distribution")
        transaction_size_query = f"""
        SELECT 
            CASE 
                WHEN TOTAL_VALUE >= 10000 THEN 'Large (>10K)'
                WHEN TOTAL_VALUE >= 5000 THEN 'Medium (5K-10K)'
                WHEN TOTAL_VALUE >= 1000 THEN 'Small (1K-5K)'
                ELSE 'Micro (<1K)'
            END as transaction_size,
            COUNT(*) as transaction_count,
            SUM(TOTAL_VALUE) as total_volume
        FROM INT_CUSTOMER_TRANSACTIONS
        GROUP BY transaction_size
        ORDER BY total_volume DESC
        """
        transaction_size = run_query(transaction_size_query)
        
        if not transaction_size.empty:
            fig_donut = px.pie(
                transaction_size,
                values='TOTAL_VOLUME',
                names='TRANSACTION_SIZE',
                title="Volume Distribution by Transaction Size",
                hole=0.4
            )
            st.plotly_chart(fig_donut, use_container_width=True)

# Run the app
if __name__ == "__main__":
    main()
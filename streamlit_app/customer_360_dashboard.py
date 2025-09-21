import streamlit as st
import pandas as pd
import altair as alt
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
    
    # Main dashboard tabs
    tab1, tab2, tab3, tab4 = st.tabs([
        "📊 Executive Summary", 
        "👥 Customer Analytics", 
        "💼 Portfolio Analysis", 
        "📈 Asset Performance"
    ])
    
    with tab1:
        show_executive_summary()
    
    with tab2:
        show_customer_analytics(customer_types, risk_levels)
    
    with tab3:
        show_portfolio_analysis(customer_types, risk_levels)
    
    with tab4:
        show_asset_performance(asset_categories)

def show_executive_summary():
    st.header("📊 Executive Summary")
    
    # KPI Metrics
    col1, col2, col3, col4 = st.columns(4)
    
    # Total AUM
    aum_query = """
    SELECT SUM(ABS(NET_INVESTMENT)) as total_aum
    FROM MART_CUSTOMER_PORTFOLIO
    """
    aum_data = run_query(aum_query)
    
    with col1:
        if not aum_data.empty and aum_data['TOTAL_AUM'].iloc[0] is not None:
            st.metric("Total AUM", f"${aum_data['TOTAL_AUM'].iloc[0]:,.0f}")
        else:
            st.metric("Total AUM", "No data")
    
    # Active Customers
    customers_query = """
    SELECT COUNT(DISTINCT CUSTOMER_ID) as active_customers
    FROM MART_CUSTOMER_PORTFOLIO
    """
    customers_data = run_query(customers_query)
    
    with col2:
        if not customers_data.empty:
            st.metric("Active Customers", f"{customers_data['ACTIVE_CUSTOMERS'].iloc[0]:,}")
    
    # Average Portfolio Size
    avg_portfolio_query = """
    SELECT AVG(ABS(NET_INVESTMENT)) as avg_portfolio
    FROM MART_CUSTOMER_PORTFOLIO
    WHERE NET_INVESTMENT IS NOT NULL
    """
    avg_portfolio_data = run_query(avg_portfolio_query)
    
    with col3:
        if not avg_portfolio_data.empty and avg_portfolio_data['AVG_PORTFOLIO'].iloc[0] is not None:
            st.metric("Avg Portfolio Size", f"${avg_portfolio_data['AVG_PORTFOLIO'].iloc[0]:,.0f}")
        else:
            st.metric("Avg Portfolio Size", "No data")
    
    # Total Transactions
    transactions_query = """
    SELECT SUM(TOTAL_TRANSACTIONS) as total_txns
    FROM MART_CUSTOMER_PORTFOLIO
    WHERE TOTAL_TRANSACTIONS IS NOT NULL
    """
    transactions_data = run_query(transactions_query)
    
    with col4:
        if not transactions_data.empty and transactions_data['TOTAL_TXNS'].iloc[0] is not None:
            st.metric("Total Transactions", f"{transactions_data['TOTAL_TXNS'].iloc[0]:,}")
        else:
            st.metric("Total Transactions", "No data")
    
    # AUM by Customer Type
    col1, col2 = st.columns(2)
    
    with col1:
        st.subheader("AUM Distribution by Customer Type")
        aum_by_type_query = """
        SELECT 
            CUSTOMER_TYPE,
            SUM(ABS(NET_INVESTMENT)) as total_aum
        FROM MART_CUSTOMER_PORTFOLIO
        WHERE NET_INVESTMENT IS NOT NULL
        GROUP BY CUSTOMER_TYPE
        ORDER BY total_aum DESC
        """
        aum_by_type = run_query(aum_by_type_query)
        
        if not aum_by_type.empty:
            # Altair pie chart
            fig_pie = alt.Chart(aum_by_type).mark_arc().encode(
                theta=alt.Theta(field="TOTAL_AUM", type="quantitative"),
                color=alt.Color(field="CUSTOMER_TYPE", type="nominal"),
                tooltip=['CUSTOMER_TYPE', 'TOTAL_AUM']
            ).resolve_scale(
                color='independent'
            ).properties(
                title="AUM Distribution by Customer Type",
                width=300,
                height=300
            )
            st.altair_chart(fig_pie, use_container_width=True)
    
    with col2:
        st.subheader("Customer Count by Risk Level")
        customers_by_risk_query = """
        SELECT 
            RISK_LEVEL,
            COUNT(*) as customer_count
        FROM MART_CUSTOMER_PORTFOLIO
        GROUP BY RISK_LEVEL
        ORDER BY customer_count DESC
        """
        customers_by_risk = run_query(customers_by_risk_query)
        
        if not customers_by_risk.empty:
            # Altair bar chart
            fig_bar = alt.Chart(customers_by_risk).mark_bar().encode(
                x=alt.X('RISK_LEVEL:N', title='Risk Level'),
                y=alt.Y('CUSTOMER_COUNT:Q', title='Customer Count'),
                color=alt.Color('RISK_LEVEL:N', legend=None),
                tooltip=['RISK_LEVEL', 'CUSTOMER_COUNT']
            ).properties(
                title="Customers by Risk Level",
                width=300,
                height=300
            )
            st.altair_chart(fig_bar, use_container_width=True)

def show_customer_analytics(customer_types, risk_levels):
    st.header("👥 Customer Analytics")
    
    # Customer Segmentation Matrix
    st.subheader("Customer Segmentation Analysis")
    
    # Create filter conditions
    customer_filter = f"CUSTOMER_TYPE IN ({','.join([f\"'{ct}'\" for ct in customer_types])})"
    risk_filter = f"RISK_LEVEL IN ({','.join([f\"'{rl}'\" for rl in risk_levels])})"
    
    segmentation_query = f"""
    SELECT 
        CUSTOMER_TYPE,
        RISK_LEVEL,
        COUNT(*) as customer_count,
        AVG(ABS(NET_INVESTMENT)) as avg_portfolio_size,
        SUM(ABS(NET_INVESTMENT)) as total_aum,
        AVG(TOTAL_TRANSACTIONS) as avg_transaction_frequency
    FROM MART_CUSTOMER_PORTFOLIO
    WHERE {customer_filter} AND {risk_filter}
    GROUP BY CUSTOMER_TYPE, RISK_LEVEL
    ORDER BY total_aum DESC
    """
    segmentation_data = run_query(segmentation_query)
    
    if not segmentation_data.empty:
        col1, col2 = st.columns(2)
        
        with col1:
            # Segmentation scatter plot
            fig_scatter = alt.Chart(segmentation_data).mark_circle(size=100).encode(
                x=alt.X('AVG_PORTFOLIO_SIZE:Q', title='Average Portfolio Size'),
                y=alt.Y('CUSTOMER_COUNT:Q', title='Customer Count'),
                color=alt.Color('RISK_LEVEL:N', title='Risk Level'),
                size=alt.Size('TOTAL_AUM:Q', title='Total AUM'),
                tooltip=['CUSTOMER_TYPE', 'RISK_LEVEL', 'CUSTOMER_COUNT', 'AVG_PORTFOLIO_SIZE', 'TOTAL_AUM']
            ).properties(
                title="Customer Segmentation Analysis",
                width=400,
                height=300
            )
            st.altair_chart(fig_scatter, use_container_width=True)
        
        with col2:
            # Transaction frequency by segment
            fig_freq = alt.Chart(segmentation_data).mark_bar().encode(
                x=alt.X('CUSTOMER_TYPE:N', title='Customer Type'),
                y=alt.Y('AVG_TRANSACTION_FREQUENCY:Q', title='Avg Transaction Frequency'),
                color=alt.Color('RISK_LEVEL:N', title='Risk Level'),
                column=alt.Column('RISK_LEVEL:N'),
                tooltip=['CUSTOMER_TYPE', 'RISK_LEVEL', 'AVG_TRANSACTION_FREQUENCY']
            ).properties(
                title="Transaction Frequency by Segment",
                width=120,
                height=200
            )
            st.altair_chart(fig_freq, use_container_width=True)
        
        # Data table
        st.subheader("Customer Segmentation Details")
        formatted_data = segmentation_data.copy()
        formatted_data['AVG_PORTFOLIO_SIZE'] = formatted_data['AVG_PORTFOLIO_SIZE'].apply(lambda x: f"${x:,.0f}" if pd.notna(x) else "N/A")
        formatted_data['TOTAL_AUM'] = formatted_data['TOTAL_AUM'].apply(lambda x: f"${x:,.0f}" if pd.notna(x) else "N/A")
        st.dataframe(formatted_data, use_container_width=True)

def show_portfolio_analysis(customer_types, risk_levels):
    st.header("💼 Portfolio Analysis")
    
    # Create filter conditions
    customer_filter = f"CUSTOMER_TYPE IN ({','.join([f\"'{ct}'\" for ct in customer_types])})"
    risk_filter = f"RISK_LEVEL IN ({','.join([f\"'{rl}'\" for rl in risk_levels])})"
    
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
        WHERE {customer_filter} AND {risk_filter}
        GROUP BY diversification_level
        ORDER BY avg_assets DESC
        """
        diversification_data = run_query(diversification_query)
        
        if not diversification_data.empty:
            # Altair scatter plot
            fig_scatter = alt.Chart(diversification_data).mark_circle(size=200).encode(
                x=alt.X('AVG_ASSETS:Q', title='Average Number of Assets'),
                y=alt.Y('AVG_PORTFOLIO_VALUE:Q', title='Average Portfolio Value'),
                color=alt.Color('DIVERSIFICATION_LEVEL:N', title='Diversification Level'),
                size=alt.Size('CUSTOMER_COUNT:Q', title='Customer Count'),
                tooltip=['DIVERSIFICATION_LEVEL', 'CUSTOMER_COUNT', 'AVG_PORTFOLIO_VALUE', 'AVG_ASSETS']
            ).properties(
                title="Diversification vs Portfolio Value",
                width=400,
                height=300
            )
            st.altair_chart(fig_scatter, use_container_width=True)
    
    with col2:
        st.subheader("Investment Capacity Analysis")
        capacity_query = f"""
        SELECT 
            INVESTMENT_CAPACITY,
            COUNT(*) as customer_count,
            AVG(ABS(NET_INVESTMENT)) as avg_portfolio_value,
            AVG(TOTAL_TRANSACTIONS) as avg_activity
        FROM MART_CUSTOMER_PORTFOLIO
        WHERE {customer_filter} AND {risk_filter}
        GROUP BY INVESTMENT_CAPACITY
        ORDER BY avg_portfolio_value DESC
        """
        capacity_data = run_query(capacity_query)
        
        if not capacity_data.empty:
            # Altair bar chart with color scale
            fig_bar = alt.Chart(capacity_data).mark_bar().encode(
                x=alt.X('INVESTMENT_CAPACITY:N', title='Investment Capacity', sort='-y'),
                y=alt.Y('AVG_PORTFOLIO_VALUE:Q', title='Average Portfolio Value'),
                color=alt.Color('CUSTOMER_COUNT:Q', scale=alt.Scale(scheme='blues'), title='Customer Count'),
                tooltip=['INVESTMENT_CAPACITY', 'AVG_PORTFOLIO_VALUE', 'CUSTOMER_COUNT', 'AVG_ACTIVITY']
            ).properties(
                title="Portfolio Value by Investment Capacity",
                width=400,
                height=300
            )
            st.altair_chart(fig_bar, use_container_width=True)

def show_asset_performance(asset_categories):
    st.header("📈 Asset Performance")
    
    # Create filter condition
    asset_filter = f"ASSET_CATEGORY IN ({','.join([f\"'{ac}'\" for ac in asset_categories])})"
    
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
        WHERE {asset_filter} AND AVG_DAILY_RETURN IS NOT NULL
        ORDER BY AVG_DAILY_RETURN DESC
        LIMIT 10
        """
        top_assets = run_query(top_assets_query)
        
        if not top_assets.empty:
            # Altair horizontal bar chart
            fig_bar = alt.Chart(top_assets).mark_bar().encode(
                x=alt.X('AVG_DAILY_RETURN_PCT:Q', title='Average Daily Return (%)'),
                y=alt.Y('ASSET_NAME:N', title='Asset Name', sort='-x'),
                color=alt.Color('ASSET_CATEGORY:N', title='Asset Category'),
                tooltip=['ASSET_NAME', 'ASSET_CATEGORY', 'AVG_DAILY_RETURN_PCT', 'SHARPE_RATIO']
            ).properties(
                title="Top 10 Assets by Daily Return",
                width=400,
                height=400
            )
            st.altair_chart(fig_bar, use_container_width=True)
    
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
        WHERE SECTOR IS NOT NULL AND {asset_filter}
        GROUP BY SECTOR
        ORDER BY sector_avg_return DESC
        """
        sector_performance = run_query(sector_performance_query)
        
        if not sector_performance.empty:
            # Altair scatter plot
            fig_scatter = alt.Chart(sector_performance).mark_circle(size=100).encode(
                x=alt.X('SECTOR_AVG_RISK:Q', title='Average Risk (%)'),
                y=alt.Y('SECTOR_AVG_RETURN:Q', title='Average Return (%)'),
                color=alt.Color('SECTOR:N', title='Sector'),
                size=alt.Size('ASSET_COUNT:Q', title='Asset Count'),
                tooltip=['SECTOR', 'ASSET_COUNT', 'SECTOR_AVG_RETURN', 'SECTOR_AVG_RISK']
            ).properties(
                title="Risk vs Return by Sector",
                width=400,
                height=300
            )
            st.altair_chart(fig_scatter, use_container_width=True)
    
    # Asset Category Distribution
    with col3:
        st.subheader("Asset Category Distribution")
        category_dist_query = f"""
        SELECT 
            ASSET_CATEGORY,
            COUNT(*) as asset_count,
            AVG(AVG_DAILY_RETURN * 100) as avg_return
        FROM MART_ASSET_PERFORMANCE
        WHERE {asset_filter}
        GROUP BY ASSET_CATEGORY
        ORDER BY avg_return DESC
        """
        category_dist = run_query(category_dist_query)
        
        if not category_dist.empty:
            # Altair donut chart
            fig_donut = alt.Chart(category_dist).mark_arc(innerRadius=50).encode(
                theta=alt.Theta(field="ASSET_COUNT", type="quantitative"),
                color=alt.Color(field="ASSET_CATEGORY", type="nominal"),
                tooltip=['ASSET_CATEGORY', 'ASSET_COUNT', 'AVG_RETURN']
            ).properties(
                title="Asset Distribution by Category",
                width=300,
                height=300
            )
            st.altair_chart(fig_donut, use_container_width=True)

def show_customer_analytics(customer_types, risk_levels):
    st.header("👥 Detailed Customer Analytics")
    
    # Create filter conditions
    customer_filter = f"CUSTOMER_TYPE IN ({','.join([f\"'{ct}'\" for ct in customer_types])})"
    risk_filter = f"RISK_LEVEL IN ({','.join([f\"'{rl}'\" for rl in risk_levels])})"
    
    # Customer Value Segments
    st.subheader("Customer Value Segmentation")
    
    value_segments_query = f"""
    SELECT 
        CASE 
            WHEN ABS(NET_INVESTMENT) >= 100000 THEN 'High Value (>100K)'
            WHEN ABS(NET_INVESTMENT) >= 50000 THEN 'Medium Value (50K-100K)'
            WHEN ABS(NET_INVESTMENT) >= 10000 THEN 'Low Value (10K-50K)'
            ELSE 'Minimal Value (<10K)'
        END as value_segment,
        CASE 
            WHEN TOTAL_TRANSACTIONS >= 50 THEN 'High Activity'
            WHEN TOTAL_TRANSACTIONS >= 20 THEN 'Medium Activity'
            WHEN TOTAL_TRANSACTIONS >= 5 THEN 'Low Activity'
            ELSE 'Minimal Activity'
        END as activity_level,
        COUNT(*) as customer_count,
        AVG(ABS(NET_INVESTMENT)) as avg_portfolio_value
    FROM MART_CUSTOMER_PORTFOLIO
    WHERE {customer_filter} AND {risk_filter}
    GROUP BY value_segment, activity_level
    ORDER BY avg_portfolio_value DESC
    """
    
    value_segments = run_query(value_segments_query)
    
    if not value_segments.empty:
        # Altair heatmap
        fig_heatmap = alt.Chart(value_segments).mark_rect().encode(
            x=alt.X('ACTIVITY_LEVEL:N', title='Activity Level'),
            y=alt.Y('VALUE_SEGMENT:N', title='Value Segment'),
            color=alt.Color('CUSTOMER_COUNT:Q', scale=alt.Scale(scheme='blues'), title='Customer Count'),
            tooltip=['VALUE_SEGMENT', 'ACTIVITY_LEVEL', 'CUSTOMER_COUNT', 'AVG_PORTFOLIO_VALUE']
        ).properties(
            title="Customer Heatmap: Value Segment vs Activity Level",
            width=500,
            height=300
        )
        st.altair_chart(fig_heatmap, use_container_width=True)
        
        # Show data table
        st.subheader("Customer Segment Details")
        formatted_segments = value_segments.copy()
        formatted_segments['AVG_PORTFOLIO_VALUE'] = formatted_segments['AVG_PORTFOLIO_VALUE'].apply(
            lambda x: f"${x:,.0f}" if pd.notna(x) else "N/A"
        )
        st.dataframe(formatted_segments, use_container_width=True)

def show_portfolio_analysis(customer_types, risk_levels):
    st.header("💼 Portfolio Analysis")
    
    # Create filter conditions
    customer_filter = f"CUSTOMER_TYPE IN ({','.join([f\"'{ct}'\" for ct in customer_types])})"
    risk_filter = f"RISK_LEVEL IN ({','.join([f\"'{rl}'\" for rl in risk_levels])})"
    
    # Portfolio metrics
    col1, col2 = st.columns(2)
    
    with col1:
        st.subheader("Portfolio Size vs Diversification")
        portfolio_metrics_query = f"""
        SELECT 
            CUSTOMER_TYPE,
            RISK_LEVEL,
            AVG(ABS(NET_INVESTMENT)) as avg_portfolio_value,
            AVG(UNIQUE_ASSETS) as avg_diversification,
            COUNT(*) as customer_count
        FROM MART_CUSTOMER_PORTFOLIO
        WHERE {customer_filter} AND {risk_filter}
        GROUP BY CUSTOMER_TYPE, RISK_LEVEL
        """
        portfolio_metrics = run_query(portfolio_metrics_query)
        
        if not portfolio_metrics.empty:
            fig_bubble = alt.Chart(portfolio_metrics).mark_circle().encode(
                x=alt.X('AVG_DIVERSIFICATION:Q', title='Average Diversification (# Assets)'),
                y=alt.Y('AVG_PORTFOLIO_VALUE:Q', title='Average Portfolio Value'),
                color=alt.Color('RISK_LEVEL:N', title='Risk Level'),
                size=alt.Size('CUSTOMER_COUNT:Q', title='Customer Count'),
                shape=alt.Shape('CUSTOMER_TYPE:N', title='Customer Type'),
                tooltip=['CUSTOMER_TYPE', 'RISK_LEVEL', 'AVG_PORTFOLIO_VALUE', 'AVG_DIVERSIFICATION', 'CUSTOMER_COUNT']
            ).properties(
                title="Portfolio Value vs Diversification",
                width=400,
                height=300
            )
            st.altair_chart(fig_bubble, use_container_width=True)
    
    with col2:
        st.subheader("Transaction Activity Distribution")
        activity_dist_query = f"""
        SELECT 
            CASE 
                WHEN TOTAL_TRANSACTIONS >= 50 THEN 'Very Active (50+)'
                WHEN TOTAL_TRANSACTIONS >= 20 THEN 'Active (20-49)'
                WHEN TOTAL_TRANSACTIONS >= 5 THEN 'Moderate (5-19)'
                ELSE 'Low Activity (<5)'
            END as activity_category,
            COUNT(*) as customer_count,
            AVG(ABS(NET_INVESTMENT)) as avg_portfolio_value
        FROM MART_CUSTOMER_PORTFOLIO
        WHERE {customer_filter} AND {risk_filter}
        GROUP BY activity_category
        ORDER BY avg_portfolio_value DESC
        """
        activity_dist = run_query(activity_dist_query)
        
        if not activity_dist.empty:
            # Altair pie chart
            fig_pie = alt.Chart(activity_dist).mark_arc().encode(
                theta=alt.Theta(field="CUSTOMER_COUNT", type="quantitative"),
                color=alt.Color(field="ACTIVITY_CATEGORY", type="nominal", scale=alt.Scale(scheme='category10')),
                tooltip=['ACTIVITY_CATEGORY', 'CUSTOMER_COUNT', 'AVG_PORTFOLIO_VALUE']
            ).properties(
                title="Customer Distribution by Activity Level",
                width=300,
                height=300
            )
            st.altair_chart(fig_pie, use_container_width=True)

# Run the app
if __name__ == "__main__":
    main()
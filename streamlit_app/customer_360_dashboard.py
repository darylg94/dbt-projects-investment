import streamlit as st
import pandas as pd
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
    WHERE NET_INVESTMENT IS NOT NULL
    """
    aum_data = run_query(aum_query)
    
    with col1:
        if not aum_data.empty and aum_data['TOTAL_AUM'].iloc[0] is not None:
            st.metric("Total AUM", f"${aum_data['TOTAL_AUM'].iloc[0]:,.0f}")
        else:
            st.metric("Total AUM", "No data")
    
    # Active Customers
    customers_query = """
    SELECT COUNT(*) as active_customers
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
    
    # Charts using native Streamlit components
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
            # Use native Streamlit bar chart
            st.bar_chart(
                aum_by_type.set_index('CUSTOMER_TYPE')['TOTAL_AUM'],
                height=300
            )
    
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
            # Use native Streamlit bar chart
            st.bar_chart(
                customers_by_risk.set_index('RISK_LEVEL')['CUSTOMER_COUNT'],
                height=300
            )

def show_customer_analytics(customer_types, risk_levels):
    st.header("👥 Customer Analytics")
    
    # Create filter conditions
    customer_filter = f"CUSTOMER_TYPE IN ({','.join([f\"'{ct}'\" for ct in customer_types])})"
    risk_filter = f"RISK_LEVEL IN ({','.join([f\"'{rl}'\" for rl in risk_levels])})"
    
    # Customer Segmentation
    st.subheader("Customer Segmentation Analysis")
    
    segmentation_query = f"""
    SELECT 
        CUSTOMER_TYPE,
        RISK_LEVEL,
        COUNT(*) as customer_count,
        AVG(ABS(NET_INVESTMENT)) as avg_portfolio_size,
        SUM(ABS(NET_INVESTMENT)) as total_aum,
        AVG(TOTAL_TRANSACTIONS) as avg_transaction_frequency
    FROM MART_CUSTOMER_PORTFOLIO
    WHERE {customer_filter} AND {risk_filter} AND NET_INVESTMENT IS NOT NULL
    GROUP BY CUSTOMER_TYPE, RISK_LEVEL
    ORDER BY total_aum DESC
    """
    segmentation_data = run_query(segmentation_query)
    
    if not segmentation_data.empty:
        # Display segmentation data
        st.dataframe(
            segmentation_data.style.format({
                'AVG_PORTFOLIO_SIZE': '${:,.0f}',
                'TOTAL_AUM': '${:,.0f}',
                'AVG_TRANSACTION_FREQUENCY': '{:.1f}'
            }),
            use_container_width=True
        )
        
        # Customer Type Distribution
        col1, col2 = st.columns(2)
        
        with col1:
            st.subheader("Portfolio Size by Customer Type")
            customer_portfolio = segmentation_data.groupby('CUSTOMER_TYPE')['AVG_PORTFOLIO_SIZE'].mean().reset_index()
            st.bar_chart(
                customer_portfolio.set_index('CUSTOMER_TYPE')['AVG_PORTFOLIO_SIZE'],
                height=300
            )
        
        with col2:
            st.subheader("Transaction Frequency by Risk Level")
            risk_frequency = segmentation_data.groupby('RISK_LEVEL')['AVG_TRANSACTION_FREQUENCY'].mean().reset_index()
            st.bar_chart(
                risk_frequency.set_index('RISK_LEVEL')['AVG_TRANSACTION_FREQUENCY'],
                height=300
            )

def show_portfolio_analysis(customer_types, risk_levels):
    st.header("💼 Portfolio Analysis")
    
    # Create filter conditions
    customer_filter = f"CUSTOMER_TYPE IN ({','.join([f\"'{ct}'\" for ct in customer_types])})"
    risk_filter = f"RISK_LEVEL IN ({','.join([f\"'{rl}'\" for rl in risk_levels])})"
    
    # Portfolio Diversification
    st.subheader("Portfolio Diversification Analysis")
    
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
        col1, col2 = st.columns(2)
        
        with col1:
            st.subheader("Diversification Distribution")
            st.bar_chart(
                diversification_data.set_index('DIVERSIFICATION_LEVEL')['CUSTOMER_COUNT'],
                height=300
            )
        
        with col2:
            st.subheader("Portfolio Value by Diversification")
            st.bar_chart(
                diversification_data.set_index('DIVERSIFICATION_LEVEL')['AVG_PORTFOLIO_VALUE'],
                height=300
            )
        
        # Show detailed data
        st.subheader("Diversification Details")
        formatted_div = diversification_data.copy()
        formatted_div['AVG_PORTFOLIO_VALUE'] = formatted_div['AVG_PORTFOLIO_VALUE'].apply(
            lambda x: f"${x:,.0f}" if pd.notna(x) else "N/A"
        )
        st.dataframe(formatted_div, use_container_width=True)

def show_asset_performance(asset_categories):
    st.header("📈 Asset Performance")
    
    # Create filter condition
    asset_filter = f"ASSET_CATEGORY IN ({','.join([f\"'{ac}'\" for ac in asset_categories])})"
    
    # Asset Performance Summary
    st.subheader("Asset Performance Summary")
    
    asset_summary_query = f"""
    SELECT 
        ASSET_CATEGORY,
        COUNT(*) as asset_count,
        AVG(COALESCE(AVG_DAILY_RETURN, 0) * 100) as avg_return_pct,
        AVG(COALESCE(DAILY_VOLATILITY, 0) * 100) as avg_volatility_pct,
        MIN(COALESCE(AVG_DAILY_RETURN, 0) * 100) as min_return_pct,
        MAX(COALESCE(AVG_DAILY_RETURN, 0) * 100) as max_return_pct
    FROM MART_ASSET_PERFORMANCE
    WHERE {asset_filter}
    GROUP BY ASSET_CATEGORY
    ORDER BY avg_return_pct DESC
    """
    asset_summary = run_query(asset_summary_query)
    
    if not asset_summary.empty:
        # Display metrics
        col1, col2, col3 = st.columns(3)
        
        with col1:
            st.subheader("Average Returns by Category")
            st.bar_chart(
                asset_summary.set_index('ASSET_CATEGORY')['AVG_RETURN_PCT'],
                height=300
            )
        
        with col2:
            st.subheader("Average Volatility by Category")
            st.bar_chart(
                asset_summary.set_index('ASSET_CATEGORY')['AVG_VOLATILITY_PCT'],
                height=300
            )
        
        with col3:
            st.subheader("Asset Count by Category")
            st.bar_chart(
                asset_summary.set_index('ASSET_CATEGORY')['ASSET_COUNT'],
                height=300
            )
        
        # Detailed table
        st.subheader("Asset Performance Details")
        formatted_assets = asset_summary.copy()
        formatted_assets['AVG_RETURN_PCT'] = formatted_assets['AVG_RETURN_PCT'].apply(
            lambda x: f"{x:.4f}%" if pd.notna(x) else "N/A"
        )
        formatted_assets['AVG_VOLATILITY_PCT'] = formatted_assets['AVG_VOLATILITY_PCT'].apply(
            lambda x: f"{x:.4f}%" if pd.notna(x) else "N/A"
        )
        st.dataframe(formatted_assets, use_container_width=True)
    
    # Top Performing Assets
    st.subheader("Top Performing Assets")
    
    top_assets_query = f"""
    SELECT 
        ASSET_NAME,
        ASSET_CATEGORY,
        SECTOR,
        (COALESCE(AVG_DAILY_RETURN, 0) * 100) as avg_daily_return_pct,
        (COALESCE(DAILY_VOLATILITY, 0) * 100) as daily_volatility_pct,
        CASE 
            WHEN DAILY_VOLATILITY > 0 
            THEN AVG_DAILY_RETURN / DAILY_VOLATILITY 
            ELSE NULL 
        END as sharpe_ratio
    FROM MART_ASSET_PERFORMANCE
    WHERE {asset_filter} AND AVG_DAILY_RETURN IS NOT NULL
    ORDER BY AVG_DAILY_RETURN DESC
    LIMIT 20
    """
    top_assets = run_query(top_assets_query)
    
    if not top_assets.empty:
        # Show top assets table
        formatted_top_assets = top_assets.copy()
        formatted_top_assets['AVG_DAILY_RETURN_PCT'] = formatted_top_assets['AVG_DAILY_RETURN_PCT'].apply(
            lambda x: f"{x:.4f}%" if pd.notna(x) else "N/A"
        )
        formatted_top_assets['DAILY_VOLATILITY_PCT'] = formatted_top_assets['DAILY_VOLATILITY_PCT'].apply(
            lambda x: f"{x:.4f}%" if pd.notna(x) else "N/A"
        )
        formatted_top_assets['SHARPE_RATIO'] = formatted_top_assets['SHARPE_RATIO'].apply(
            lambda x: f"{x:.4f}" if pd.notna(x) else "N/A"
        )
        st.dataframe(formatted_top_assets, use_container_width=True)
        
        # Simple line chart for top 10 assets
        top_10_returns = top_assets.head(10)[['ASSET_NAME', 'AVG_DAILY_RETURN_PCT']].set_index('ASSET_NAME')
        st.subheader("Top 10 Assets - Daily Returns")
        st.bar_chart(top_10_returns, height=400)

def show_customer_analytics(customer_types, risk_levels):
    st.header("👥 Customer Analytics")
    
    # Create filter conditions
    customer_filter = f"CUSTOMER_TYPE IN ({','.join([f\"'{ct}'\" for ct in customer_types])})"
    risk_filter = f"RISK_LEVEL IN ({','.join([f\"'{rl}'\" for rl in risk_levels])})"
    
    # Customer Segmentation
    st.subheader("Customer Segmentation Analysis")
    
    segmentation_query = f"""
    SELECT 
        CUSTOMER_TYPE,
        RISK_LEVEL,
        COUNT(*) as customer_count,
        AVG(ABS(NET_INVESTMENT)) as avg_portfolio_size,
        SUM(ABS(NET_INVESTMENT)) as total_aum,
        AVG(TOTAL_TRANSACTIONS) as avg_transaction_frequency
    FROM MART_CUSTOMER_PORTFOLIO
    WHERE {customer_filter} AND {risk_filter} AND NET_INVESTMENT IS NOT NULL
    GROUP BY CUSTOMER_TYPE, RISK_LEVEL
    ORDER BY total_aum DESC
    """
    segmentation_data = run_query(segmentation_query)
    
    if not segmentation_data.empty:
        # Customer Type Analysis
        col1, col2 = st.columns(2)
        
        with col1:
            st.subheader("AUM by Customer Type")
            aum_by_type = segmentation_data.groupby('CUSTOMER_TYPE')['TOTAL_AUM'].sum()
            st.bar_chart(aum_by_type, height=300)
        
        with col2:
            st.subheader("Customer Count by Risk Level")
            count_by_risk = segmentation_data.groupby('RISK_LEVEL')['CUSTOMER_COUNT'].sum()
            st.bar_chart(count_by_risk, height=300)
        
        # Detailed segmentation table
        st.subheader("Customer Segmentation Details")
        formatted_data = segmentation_data.copy()
        formatted_data['AVG_PORTFOLIO_SIZE'] = formatted_data['AVG_PORTFOLIO_SIZE'].apply(
            lambda x: f"${x:,.0f}" if pd.notna(x) else "N/A"
        )
        formatted_data['TOTAL_AUM'] = formatted_data['TOTAL_AUM'].apply(
            lambda x: f"${x:,.0f}" if pd.notna(x) else "N/A"
        )
        st.dataframe(formatted_data, use_container_width=True)

def show_portfolio_analysis(customer_types, risk_levels):
    st.header("💼 Portfolio Analysis")
    
    # Create filter conditions
    customer_filter = f"CUSTOMER_TYPE IN ({','.join([f\"'{ct}'\" for ct in customer_types])})"
    risk_filter = f"RISK_LEVEL IN ({','.join([f\"'{rl}'\" for rl in risk_levels])})"
    
    # Portfolio Value Distribution
    st.subheader("Portfolio Value Distribution")
    
    value_distribution_query = f"""
    SELECT 
        CASE 
            WHEN ABS(NET_INVESTMENT) >= 100000 THEN 'High Value (>100K)'
            WHEN ABS(NET_INVESTMENT) >= 50000 THEN 'Medium Value (50K-100K)'
            WHEN ABS(NET_INVESTMENT) >= 10000 THEN 'Low Value (10K-50K)'
            ELSE 'Minimal Value (<10K)'
        END as value_segment,
        COUNT(*) as customer_count,
        AVG(ABS(NET_INVESTMENT)) as avg_portfolio_value
    FROM MART_CUSTOMER_PORTFOLIO
    WHERE {customer_filter} AND {risk_filter} AND NET_INVESTMENT IS NOT NULL
    GROUP BY value_segment
    ORDER BY avg_portfolio_value DESC
    """
    
    value_distribution = run_query(value_distribution_query)
    
    if not value_distribution.empty:
        col1, col2 = st.columns(2)
        
        with col1:
            st.subheader("Customer Count by Value Segment")
            st.bar_chart(
                value_distribution.set_index('VALUE_SEGMENT')['CUSTOMER_COUNT'],
                height=300
            )
        
        with col2:
            st.subheader("Average Portfolio Value by Segment")
            st.bar_chart(
                value_distribution.set_index('VALUE_SEGMENT')['AVG_PORTFOLIO_VALUE'],
                height=300
            )
        
        # Show detailed data
        st.subheader("Value Segment Details")
        formatted_value = value_distribution.copy()
        formatted_value['AVG_PORTFOLIO_VALUE'] = formatted_value['AVG_PORTFOLIO_VALUE'].apply(
            lambda x: f"${x:,.0f}" if pd.notna(x) else "N/A"
        )
        st.dataframe(formatted_value, use_container_width=True)

def show_asset_performance(asset_categories):
    st.header("📈 Asset Performance")
    
    # Create filter condition
    asset_filter = f"ASSET_CATEGORY IN ({','.join([f\"'{ac}'\" for ac in asset_categories])})"
    
    # Sector Performance
    st.subheader("Sector Performance Analysis")
    
    sector_performance_query = f"""
    SELECT 
        SECTOR,
        COUNT(*) as asset_count,
        AVG(COALESCE(AVG_DAILY_RETURN, 0) * 100) as sector_avg_return,
        AVG(COALESCE(DAILY_VOLATILITY, 0) * 100) as sector_avg_risk
    FROM MART_ASSET_PERFORMANCE
    WHERE SECTOR IS NOT NULL AND {asset_filter}
    GROUP BY SECTOR
    ORDER BY sector_avg_return DESC
    LIMIT 10
    """
    sector_performance = run_query(sector_performance_query)
    
    if not sector_performance.empty:
        col1, col2 = st.columns(2)
        
        with col1:
            st.subheader("Average Return by Sector")
            st.bar_chart(
                sector_performance.set_index('SECTOR')['SECTOR_AVG_RETURN'],
                height=400
            )
        
        with col2:
            st.subheader("Average Risk by Sector")
            st.bar_chart(
                sector_performance.set_index('SECTOR')['SECTOR_AVG_RISK'],
                height=400
            )
        
        # Sector performance table
        st.subheader("Sector Performance Details")
        formatted_sectors = sector_performance.copy()
        formatted_sectors['SECTOR_AVG_RETURN'] = formatted_sectors['SECTOR_AVG_RETURN'].apply(
            lambda x: f"{x:.4f}%" if pd.notna(x) else "N/A"
        )
        formatted_sectors['SECTOR_AVG_RISK'] = formatted_sectors['SECTOR_AVG_RISK'].apply(
            lambda x: f"{x:.4f}%" if pd.notna(x) else "N/A"
        )
        st.dataframe(formatted_sectors, use_container_width=True)

# Transaction Analysis
st.header("🔄 Recent Transaction Insights")

# Show recent transaction summary from INT_CUSTOMER_TRANSACTIONS
transaction_summary_query = """
SELECT 
    TRANSACTION_TYPE,
    COUNT(*) as transaction_count,
    SUM(TOTAL_VALUE) as total_volume,
    AVG(TOTAL_VALUE) as avg_transaction_size
FROM INT_CUSTOMER_TRANSACTIONS
WHERE TRANSACTION_DATE >= DATEADD('month', -3, CURRENT_DATE())
GROUP BY TRANSACTION_TYPE
ORDER BY total_volume DESC
"""

transaction_summary = run_query(transaction_summary_query)

if not transaction_summary.empty:
    col1, col2 = st.columns(2)
    
    with col1:
        st.subheader("Transaction Volume by Type (Last 3 Months)")
        st.bar_chart(
            transaction_summary.set_index('TRANSACTION_TYPE')['TOTAL_VOLUME'],
            height=300
        )
    
    with col2:
        st.subheader("Transaction Count by Type (Last 3 Months)")
        st.bar_chart(
            transaction_summary.set_index('TRANSACTION_TYPE')['TRANSACTION_COUNT'],
            height=300
        )
    
    # Transaction summary table
    st.subheader("Transaction Summary Details")
    formatted_txn = transaction_summary.copy()
    formatted_txn['TOTAL_VOLUME'] = formatted_txn['TOTAL_VOLUME'].apply(
        lambda x: f"${x:,.0f}" if pd.notna(x) else "N/A"
    )
    formatted_txn['AVG_TRANSACTION_SIZE'] = formatted_txn['AVG_TRANSACTION_SIZE'].apply(
        lambda x: f"${x:,.0f}" if pd.notna(x) else "N/A"
    )
    st.dataframe(formatted_txn, use_container_width=True)

# Run the app
if __name__ == "__main__":
    main()
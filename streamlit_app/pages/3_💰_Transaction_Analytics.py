import streamlit as st
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
from datetime import datetime, timedelta
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(__file__)))
from customer_360_dashboard import run_query

st.set_page_config(page_title="Transaction Analytics", page_icon="💰", layout="wide")

st.title("💰 Transaction Analytics Dashboard")

# Sidebar filters
st.sidebar.header("Filters")

# Date range filter
date_range = st.sidebar.date_input(
    "Select Date Range",
    value=(datetime.now() - timedelta(days=365), datetime.now()),
    key="transaction_date_range"
)

customer_types = st.sidebar.multiselect(
    "Customer Type",
    options=["Premium", "Mass", "Professional"],
    default=["Premium", "Mass", "Professional"]
)

transaction_types = st.sidebar.multiselect(
    "Transaction Type",
    options=["Buy", "Sell"],
    default=["Buy", "Sell"]
)

channels = st.sidebar.multiselect(
    "Channels",
    options=["Internet Banking", "Mobile App", "Branch"],
    default=["Internet Banking", "Mobile App", "Branch"]
)

# Create filter conditions
customer_filter = f"customer_type IN ({','.join([f\"'{ct}'\" for ct in customer_types])})"
transaction_filter = f"transaction_type IN ({','.join([f\"'{tt}'\" for tt in transaction_types])})"
channel_filter = f"channel IN ({','.join([f\"'{ch}'\" for ch in channels])})" if channels else "1=1"
date_filter = f"transaction_date BETWEEN '{date_range[0]}' AND '{date_range[1]}'"

# Transaction Overview
st.header("📊 Transaction Overview")

# Key metrics
col1, col2, col3, col4 = st.columns(4)

# Total transaction volume
volume_query = f"""
SELECT SUM(total_value) as total_volume
FROM transaction_analytics_view
WHERE {customer_filter} AND {transaction_filter} AND {channel_filter} AND {date_filter}
"""
volume_data = run_query(volume_query)

with col1:
    if not volume_data.empty:
        st.metric("Total Volume", f"${volume_data['TOTAL_VOLUME'].iloc[0]:,.0f}")

# Transaction count
count_query = f"""
SELECT COUNT(*) as transaction_count
FROM transaction_analytics_view
WHERE {customer_filter} AND {transaction_filter} AND {channel_filter} AND {date_filter}
"""
count_data = run_query(count_query)

with col2:
    if not count_data.empty:
        st.metric("Total Transactions", f"{count_data['TRANSACTION_COUNT'].iloc[0]:,}")

# Average transaction size
avg_size_query = f"""
SELECT AVG(total_value) as avg_transaction_size
FROM transaction_analytics_view
WHERE {customer_filter} AND {transaction_filter} AND {channel_filter} AND {date_filter}
"""
avg_size_data = run_query(avg_size_query)

with col3:
    if not avg_size_data.empty:
        st.metric("Avg Transaction Size", f"${avg_size_data['AVG_TRANSACTION_SIZE'].iloc[0]:,.0f}")

# Unique customers
unique_customers_query = f"""
SELECT COUNT(DISTINCT customer_id) as unique_customers
FROM transaction_analytics_view
WHERE {customer_filter} AND {transaction_filter} AND {channel_filter} AND {date_filter}
"""
unique_customers_data = run_query(unique_customers_query)

with col4:
    if not unique_customers_data.empty:
        st.metric("Active Customers", f"{unique_customers_data['UNIQUE_CUSTOMERS'].iloc[0]:,}")

# Monthly Transaction Trends
st.header("📈 Monthly Transaction Trends")

monthly_trends_query = f"""
SELECT 
    transaction_month,
    transaction_type,
    SUM(total_value) as monthly_volume,
    COUNT(*) as transaction_count,
    COUNT(DISTINCT customer_id) as active_customers,
    AVG(total_value) as avg_transaction_size
FROM transaction_analytics_view
WHERE {customer_filter} AND {transaction_filter} AND {channel_filter} AND {date_filter}
GROUP BY transaction_month, transaction_type
ORDER BY transaction_month, transaction_type
"""
monthly_trends = run_query(monthly_trends_query)

if not monthly_trends.empty:
    col1, col2 = st.columns(2)
    
    with col1:
        # Monthly volume trends
        fig_volume = px.line(
            monthly_trends,
            x='TRANSACTION_MONTH',
            y='MONTHLY_VOLUME',
            color='TRANSACTION_TYPE',
            title="Monthly Transaction Volume Trends",
            markers=True
        )
        st.plotly_chart(fig_volume, use_container_width=True)
    
    with col2:
        # Monthly transaction count trends
        fig_count = px.line(
            monthly_trends,
            x='TRANSACTION_MONTH',
            y='TRANSACTION_COUNT',
            color='TRANSACTION_TYPE',
            title="Monthly Transaction Count Trends",
            markers=True
        )
        st.plotly_chart(fig_count, use_container_width=True)

# Channel Analysis
st.header("📱 Channel Performance Analysis")

channel_performance_query = f"""
SELECT 
    channel,
    asset_category,
    COUNT(*) as transaction_count,
    SUM(total_value) as channel_volume,
    COUNT(DISTINCT customer_id) as unique_customers,
    AVG(total_value) as avg_transaction_size
FROM transaction_analytics_view
WHERE {customer_filter} AND {transaction_filter} AND {channel_filter} AND {date_filter}
GROUP BY channel, asset_category
ORDER BY channel_volume DESC
"""
channel_performance = run_query(channel_performance_query)

if not channel_performance.empty:
    col1, col2 = st.columns(2)
    
    with col1:
        # Channel volume by asset category
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
        # Channel efficiency (customers per transaction)
        channel_efficiency = channel_performance.copy()
        channel_efficiency['EFFICIENCY'] = channel_efficiency['UNIQUE_CUSTOMERS'] / channel_efficiency['TRANSACTION_COUNT']
        
        fig_efficiency = px.bar(
            channel_efficiency,
            x='CHANNEL',
            y='EFFICIENCY',
            color='AVG_TRANSACTION_SIZE',
            title="Channel Efficiency (Customers per Transaction)",
            color_continuous_scale='Blues'
        )
        st.plotly_chart(fig_efficiency, use_container_width=True)

# Transaction Size Analysis
st.header("💳 Transaction Size Analysis")

transaction_size_query = f"""
SELECT 
    CASE 
        WHEN total_value >= 50000 THEN 'Very Large (>50K)'
        WHEN total_value >= 10000 THEN 'Large (10K-50K)'
        WHEN total_value >= 5000 THEN 'Medium (5K-10K)'
        WHEN total_value >= 1000 THEN 'Small (1K-5K)'
        ELSE 'Micro (<1K)'
    END as transaction_size,
    transaction_type,
    COUNT(*) as transaction_count,
    SUM(total_value) as total_volume,
    AVG(total_value) as avg_value
FROM transaction_analytics_view
WHERE {customer_filter} AND {transaction_filter} AND {channel_filter} AND {date_filter}
GROUP BY transaction_size, transaction_type
ORDER BY avg_value DESC
"""
transaction_size = run_query(transaction_size_query)

if not transaction_size.empty:
    col1, col2 = st.columns(2)
    
    with col1:
        # Transaction size distribution by volume
        fig_size_volume = px.sunburst(
            transaction_size,
            path=['TRANSACTION_SIZE', 'TRANSACTION_TYPE'],
            values='TOTAL_VOLUME',
            title="Transaction Volume Distribution by Size & Type"
        )
        st.plotly_chart(fig_size_volume, use_container_width=True)
    
    with col2:
        # Transaction size distribution by count
        fig_size_count = px.sunburst(
            transaction_size,
            path=['TRANSACTION_SIZE', 'TRANSACTION_TYPE'],
            values='TRANSACTION_COUNT',
            title="Transaction Count Distribution by Size & Type"
        )
        st.plotly_chart(fig_size_count, use_container_width=True)

# Detailed Transaction Analysis
st.header("📋 Detailed Transaction Analysis")

# Customer transaction patterns
customer_patterns_query = f"""
SELECT 
    customer_id,
    customer_type,
    risk_level,
    COUNT(*) as total_transactions,
    SUM(total_value) as total_volume,
    AVG(total_value) as avg_transaction_size,
    COUNT(DISTINCT asset_category) as asset_categories,
    COUNT(DISTINCT channel) as channels_used
FROM transaction_analytics_view
WHERE {customer_filter} AND {transaction_filter} AND {channel_filter} AND {date_filter}
GROUP BY customer_id, customer_type, risk_level
ORDER BY total_volume DESC
LIMIT 50
"""
customer_patterns = run_query(customer_patterns_query)

if not customer_patterns.empty:
    st.subheader("Top Customer Transaction Patterns")
    st.dataframe(
        customer_patterns.style.format({
            'TOTAL_VOLUME': '${:,.0f}',
            'AVG_TRANSACTION_SIZE': '${:,.0f}'
        }),
        use_container_width=True
    )

# Asset popularity analysis
st.subheader("🎯 Most Traded Assets")
asset_popularity_query = f"""
SELECT 
    asset_name,
    asset_category,
    sector,
    COUNT(*) as transaction_count,
    SUM(total_value) as total_volume,
    COUNT(DISTINCT customer_id) as unique_customers,
    AVG(total_value) as avg_transaction_size
FROM transaction_analytics_view
WHERE {customer_filter} AND {transaction_filter} AND {channel_filter} AND {date_filter}
GROUP BY asset_name, asset_category, sector
ORDER BY transaction_count DESC
LIMIT 20
"""
asset_popularity = run_query(asset_popularity_query)

if not asset_popularity.empty:
    fig_popularity = px.treemap(
        asset_popularity,
        path=['ASSET_CATEGORY', 'ASSET_NAME'],
        values='TOTAL_VOLUME',
        color='TRANSACTION_COUNT',
        title="Most Traded Assets by Volume & Transaction Count",
        color_continuous_scale='Viridis'
    )
    st.plotly_chart(fig_popularity, use_container_width=True)

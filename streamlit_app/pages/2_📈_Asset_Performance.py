import streamlit as st
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
from plotly.subplots import make_subplots
import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(__file__)))
from customer_360_dashboard import run_query

st.set_page_config(page_title="Asset Performance", page_icon="📈", layout="wide")

st.title("📈 Asset Performance Analytics")

# Sidebar filters
st.sidebar.header("Filters")
asset_categories = st.sidebar.multiselect(
    "Asset Category",
    options=["Stock", "Bond", "MTF"],
    default=["Stock", "Bond", "MTF"]
)

sectors = st.sidebar.multiselect(
    "Sectors",
    options=["Technology", "Healthcare", "Financial Services", "Consumer Cyclical", "Communication Services"],
    default=[]
)

# Risk category filter
risk_categories = st.sidebar.multiselect(
    "Risk Category",
    options=["Low Risk", "Medium Risk", "High Risk"],
    default=["Low Risk", "Medium Risk", "High Risk"]
)

# Create filter conditions
asset_filter = f"asset_category IN ({','.join([f\"'{ac}'\" for ac in asset_categories])})"
sector_filter = f"sector IN ({','.join([f\"'{s}'\" for s in sectors])})" if sectors else "1=1"
risk_filter = f"risk_category IN ({','.join([f\"'{rc}'\" for rc in risk_categories])})"

# Performance Overview
st.header("🎯 Performance Overview")

# Key metrics
col1, col2, col3, col4 = st.columns(4)

# Total assets
total_assets_query = f"""
SELECT COUNT(*) as total_assets
FROM asset_analytics_view
WHERE {asset_filter} AND {sector_filter} AND {risk_filter}
"""
total_assets = run_query(total_assets_query)

with col1:
    if not total_assets.empty:
        st.metric("Total Assets", f"{total_assets['TOTAL_ASSETS'].iloc[0]:,}")

# Average return
avg_return_query = f"""
SELECT AVG(avg_daily_return_pct) as avg_return
FROM asset_analytics_view
WHERE {asset_filter} AND {sector_filter} AND {risk_filter}
"""
avg_return = run_query(avg_return_query)

with col2:
    if not avg_return.empty:
        st.metric("Average Daily Return", f"{avg_return['AVG_RETURN'].iloc[0]:.4f}%")

# Average volatility
avg_vol_query = f"""
SELECT AVG(daily_volatility_pct) as avg_volatility
FROM asset_analytics_view
WHERE {asset_filter} AND {sector_filter} AND {risk_filter}
"""
avg_vol = run_query(avg_vol_query)

with col3:
    if not avg_vol.empty:
        st.metric("Average Volatility", f"{avg_vol['AVG_VOLATILITY'].iloc[0]:.4f}%")

# Best Sharpe ratio
best_sharpe_query = f"""
SELECT MAX(sharpe_ratio) as best_sharpe
FROM asset_analytics_view
WHERE {asset_filter} AND {sector_filter} AND {risk_filter} AND sharpe_ratio IS NOT NULL
"""
best_sharpe = run_query(best_sharpe_query)

with col4:
    if not best_sharpe.empty:
        st.metric("Best Sharpe Ratio", f"{best_sharpe['BEST_SHARPE'].iloc[0]:.4f}")

# Sector Performance Analysis
st.header("🏭 Sector Performance Analysis")

sector_performance_query = f"""
SELECT 
    sector,
    COUNT(*) as asset_count,
    AVG(avg_daily_return_pct) as sector_avg_return,
    AVG(daily_volatility_pct) as sector_avg_risk,
    AVG(sharpe_ratio) as sector_sharpe_ratio,
    AVG(total_return_pct) as sector_total_return
FROM asset_analytics_view
WHERE sector IS NOT NULL AND {asset_filter} AND {sector_filter} AND {risk_filter}
GROUP BY sector
ORDER BY sector_avg_return DESC
"""
sector_performance = run_query(sector_performance_query)

if not sector_performance.empty:
    col1, col2 = st.columns(2)
    
    with col1:
        # Risk vs Return scatter plot
        fig_scatter = px.scatter(
            sector_performance,
            x='SECTOR_AVG_RISK',
            y='SECTOR_AVG_RETURN',
            size='ASSET_COUNT',
            color='SECTOR_SHARPE_RATIO',
            hover_data=['SECTOR', 'ASSET_COUNT'],
            title="Sector Risk vs Return Analysis",
            labels={
                'SECTOR_AVG_RISK': 'Average Risk (%)',
                'SECTOR_AVG_RETURN': 'Average Return (%)'
            }
        )
        st.plotly_chart(fig_scatter, use_container_width=True)
    
    with col2:
        # Sector performance bar chart
        fig_bar = px.bar(
            sector_performance.head(10),
            x='SECTOR_AVG_RETURN',
            y='SECTOR',
            color='SECTOR_SHARPE_RATIO',
            title="Top 10 Sectors by Average Return",
            orientation='h',
            color_continuous_scale='RdYlGn'
        )
        st.plotly_chart(fig_bar, use_container_width=True)

# Asset Category Analysis
st.header("📊 Asset Category Performance")

category_performance_query = f"""
SELECT 
    asset_category,
    risk_category,
    COUNT(*) as asset_count,
    AVG(avg_daily_return_pct) as avg_return,
    AVG(daily_volatility_pct) as avg_volatility,
    MAX(total_return_pct) as best_asset_return,
    MIN(total_return_pct) as worst_asset_return,
    AVG(sharpe_ratio) as avg_sharpe_ratio
FROM asset_analytics_view
WHERE {asset_filter} AND {sector_filter} AND {risk_filter}
GROUP BY asset_category, risk_category
ORDER BY asset_category, avg_return DESC
"""
category_performance = run_query(category_performance_query)

if not category_performance.empty:
    # Grouped bar chart for asset categories
    fig_grouped = px.bar(
        category_performance,
        x='ASSET_CATEGORY',
        y='AVG_RETURN',
        color='RISK_CATEGORY',
        title="Average Return by Asset Category & Risk Level",
        barmode='group',
        hover_data=['ASSET_COUNT', 'AVG_SHARPE_RATIO']
    )
    st.plotly_chart(fig_grouped, use_container_width=True)

# Top Performing Assets
st.header("🏆 Top Performing Assets")

top_assets_query = f"""
SELECT 
    asset_name,
    asset_category,
    sector,
    avg_daily_return_pct,
    daily_volatility_pct,
    total_return_pct,
    sharpe_ratio,
    trading_days
FROM asset_analytics_view
WHERE {asset_filter} AND {sector_filter} AND {risk_filter}
ORDER BY sharpe_ratio DESC NULLS LAST
LIMIT 20
"""
top_assets = run_query(top_assets_query)

if not top_assets.empty:
    col1, col2 = st.columns(2)
    
    with col1:
        # Top assets by Sharpe ratio
        fig_top_sharpe = px.bar(
            top_assets.head(10),
            x='SHARPE_RATIO',
            y='ASSET_NAME',
            color='ASSET_CATEGORY',
            title="Top 10 Assets by Sharpe Ratio",
            orientation='h'
        )
        fig_top_sharpe.update_layout(height=500)
        st.plotly_chart(fig_top_sharpe, use_container_width=True)
    
    with col2:
        # Risk vs Return for top assets
        fig_risk_return = px.scatter(
            top_assets,
            x='DAILY_VOLATILITY_PCT',
            y='AVG_DAILY_RETURN_PCT',
            size='TRADING_DAYS',
            color='ASSET_CATEGORY',
            hover_data=['ASSET_NAME', 'SHARPE_RATIO'],
            title="Risk vs Return for Top Assets"
        )
        st.plotly_chart(fig_risk_return, use_container_width=True)

# Detailed performance table
st.header("📋 Detailed Asset Performance")
if not top_assets.empty:
    st.dataframe(
        top_assets.style.format({
            'AVG_DAILY_RETURN_PCT': '{:.4f}%',
            'DAILY_VOLATILITY_PCT': '{:.4f}%',
            'TOTAL_RETURN_PCT': '{:.2f}%',
            'SHARPE_RATIO': '{:.4f}'
        }),
        use_container_width=True
    )

# Performance distribution
st.header("📊 Performance Distribution")

distribution_query = f"""
SELECT 
    CASE 
        WHEN total_return_pct >= 20 THEN 'Excellent (>20%)'
        WHEN total_return_pct >= 10 THEN 'Good (10-20%)'
        WHEN total_return_pct >= 0 THEN 'Positive (0-10%)'
        WHEN total_return_pct >= -10 THEN 'Slight Loss (0 to -10%)'
        ELSE 'Poor (<-10%)'
    END as performance_category,
    COUNT(*) as asset_count,
    AVG(avg_daily_return_pct) as avg_return,
    AVG(daily_volatility_pct) as avg_volatility
FROM asset_analytics_view
WHERE {asset_filter} AND {sector_filter} AND {risk_filter}
GROUP BY performance_category
ORDER BY avg_return DESC
"""
distribution_data = run_query(distribution_query)

if not distribution_data.empty:
    fig_dist = px.pie(
        distribution_data,
        values='ASSET_COUNT',
        names='PERFORMANCE_CATEGORY',
        title="Asset Distribution by Performance Category",
        hole=0.4
    )
    st.plotly_chart(fig_dist, use_container_width=True)

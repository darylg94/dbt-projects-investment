# Customer 360 Analytics - Streamlit in Snowflake (SIS) App

A comprehensive Streamlit in Snowflake dashboard for Customer 360 analytics built on top of the DBT Investment Analytics project.

## 🎯 Overview

This dashboard provides interactive visualizations and self-serve analytics capabilities using [Streamlit in Snowflake](https://docs.snowflake.com/en/developer-guide/streamlit/getting-started), eliminating the need for external infrastructure or connectors.

## 📊 Dashboard Features

### **Main Dashboard (customer_360_dashboard.py)**
- **Executive Summary**: Key KPIs, AUM distribution, customer metrics
- **Customer Analytics**: Segmentation matrix, risk analysis, lifecycle tracking
- **Portfolio Analysis**: Diversification, allocation, risk alignment
- **Asset Performance**: Sector analysis, risk-return metrics
- **Transaction Analysis**: Trends, channel performance, size distribution

### **Specialized Pages**
1. **🎯 Customer Segmentation**: Deep-dive customer analysis
2. **📈 Asset Performance**: Comprehensive asset analytics
3. **💰 Transaction Analytics**: Transaction patterns and trends

## 🚀 Streamlit in Snowflake Deployment

### **Method 1: Using Snowsight UI**

1. **Navigate to Streamlit Apps**:
   - Sign in to Snowsight
   - Go to Projects → Streamlit
   - Click "+ Streamlit App"

2. **Configure App**:
   - **Name**: `customer_360_analytics`
   - **Database**: `FAR_TRANS_DB`
   - **Schema**: `STREAMLIT_APPS`
   - **Warehouse**: `FAR_TRANS_WH`

3. **Upload Files**:
   - Copy the content from `customer_360_dashboard.py`
   - Add `environment.yml` for package dependencies
   - Upload additional pages if needed

4. **Deploy**: Click "Create" to deploy the app

### **Method 2: Using SQL Commands**

Run the `deploy_sis_app.sql` script in Snowflake:

```sql
-- Create Streamlit app using SQL
USE DATABASE FAR_TRANS_DB;
USE SCHEMA STREAMLIT_APPS;

CREATE STREAMLIT customer_360_analytics
    ROOT_LOCATION = '@streamlit_stage/customer_360_analytics'
    MAIN_FILE = 'customer_360_dashboard.py'
    QUERY_WAREHOUSE = FAR_TRANS_WH;
```

### **Method 3: Using Snowflake CLI**

```bash
# Install Snowflake CLI
pip install snowflake-cli-labs

# Deploy app
snow streamlit deploy \
    --connection="your_connection" \
    --name="customer_360_analytics" \
    --database="FAR_TRANS_DB" \
    --schema="STREAMLIT_APPS" \
    --warehouse="FAR_TRANS_WH"
```

## 🔧 Key SIS Features

### **Native Integration**
- **No External Connectors**: Uses Snowflake's native session
- **Built-in Authentication**: Leverages Snowflake's security model
- **Automatic Scaling**: Scales with Snowflake infrastructure
- **Cost Optimization**: Pay only for warehouse usage

### **Connection Management**
```python
# Native SIS connection - no credentials needed
@st.cache_resource
def get_session():
    return st.connection('snowflake').session()

# Query execution with native session
session = get_session()
result = session.sql(query).collect()
```

### **Environment Configuration**
```yaml
# environment.yml for SIS
name: customer_360_analytics
channels:
  - snowflake
  - conda-forge
dependencies:
  - python=3.11
  - streamlit=1.46.1
  - plotly=5.17.0
  - pandas=2.1.3
```

## 📋 Prerequisites

Based on [Snowflake's documentation](https://docs.snowflake.com/en/developer-guide/streamlit/getting-started):

### **Required Privileges**
```sql
-- Grant privileges for creating Streamlit apps
GRANT USAGE ON DATABASE FAR_TRANS_DB TO ROLE your_role;
GRANT USAGE ON SCHEMA FAR_TRANS_DB.STREAMLIT_APPS TO ROLE your_role;
GRANT CREATE STREAMLIT ON SCHEMA FAR_TRANS_DB.STREAMLIT_APPS TO ROLE your_role;
GRANT CREATE STAGE ON SCHEMA FAR_TRANS_DB.STREAMLIT_APPS TO ROLE your_role;
GRANT USAGE ON WAREHOUSE FAR_TRANS_WH TO ROLE your_role;
```

### **Data Access Privileges**
```sql
-- Grant access to mart tables
GRANT SELECT ON MART_CUSTOMER_PORTFOLIO TO ROLE your_role;
GRANT SELECT ON MART_ASSET_PERFORMANCE TO ROLE your_role;
GRANT SELECT ON INT_CUSTOMER_TRANSACTIONS TO ROLE your_role;
GRANT SELECT ON INT_ASSET_DAILY_METRICS TO ROLE your_role;
```

## 🎮 Usage & Features

### **Interactive Dashboards**
- **Real-time Data**: Direct access to Snowflake tables
- **Dynamic Filtering**: Interactive filters for all visualizations
- **Multi-page Navigation**: Specialized analytics pages
- **Export Capabilities**: Built-in Streamlit sharing features

### **Business Analytics**
- **Customer Segmentation**: Risk level, customer type, portfolio value analysis
- **Asset Performance**: Sector analysis, risk-return metrics, volatility tracking
- **Transaction Patterns**: Channel performance, size distribution, trends
- **Portfolio Analysis**: Diversification, allocation, risk alignment

### **Visualization Types**
- **📊 Bar Charts**: Performance comparisons, customer counts
- **🥧 Pie Charts**: Distribution analysis, portfolio allocation
- **📈 Line Charts**: Time series trends, monthly patterns
- **🎯 Scatter Plots**: Risk vs return analysis
- **🗺️ Heatmaps**: Customer segmentation matrix
- **🌳 Treemaps**: Hierarchical data visualization

## 🔍 Monitoring & Management

### **App Management**
```sql
-- Show Streamlit apps
SHOW STREAMLITS IN SCHEMA FAR_TRANS_DB.STREAMLIT_APPS;

-- Describe app
DESCRIBE STREAMLIT customer_360_analytics;

-- Grant usage to other roles
GRANT USAGE ON STREAMLIT customer_360_analytics TO ROLE analyst_role;
```

### **Performance Optimization**
- **Warehouse Sizing**: Start with X-Small, scale as needed
- **Query Optimization**: Use appropriate warehouse for complex queries
- **Caching**: Leverage Streamlit's built-in caching
- **Auto-suspend**: Set minimum 30 seconds for initialization

## 🎯 Business Value

### **Self-Serve Analytics**
- **No Technical Barriers**: Business users can access insights directly
- **Real-time Data**: Always up-to-date information
- **Interactive Exploration**: Dynamic filtering and drill-down capabilities
- **Secure Access**: Leverages Snowflake's security model

### **Cost Benefits**
- **No External Infrastructure**: Runs entirely within Snowflake
- **Pay-per-use**: Only pay for warehouse usage during app execution
- **Simplified Maintenance**: No external systems to manage
- **Integrated Security**: Uses existing Snowflake roles and permissions

### **Operational Efficiency**
- **Instant Deployment**: Deploy directly from Snowsight
- **Version Control**: Integrated with Snowflake's object management
- **Collaboration**: Easy sharing with role-based access
- **Scalability**: Automatically scales with Snowflake infrastructure

## 🔧 Troubleshooting

### **Common Issues**
1. **App Won't Load**: Check warehouse is running and user has privileges
2. **No Data**: Verify DBT models are deployed and populated
3. **Permission Errors**: Ensure proper grants on schemas and tables
4. **Performance**: Consider larger warehouse for complex queries

### **Best Practices**
- Use dedicated warehouse for Streamlit apps
- Implement query caching for better performance
- Start with smaller warehouses and scale up as needed
- Use separate warehouses for heavy analytical queries

This Streamlit in Snowflake app provides a powerful, native analytics platform that leverages your DBT models for comprehensive Customer 360 insights!
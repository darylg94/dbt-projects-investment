# Incremental Models Guide

This guide explains how to implement and use incremental models in the DBT Investment Analytics project.

## 🎯 Why Incremental Models?

### **Performance Benefits**
- **Speed**: Process only new/changed data (10x-100x faster)
- **Cost**: Reduce Snowflake compute costs by 80-95%
- **Scalability**: Handle datasets that grow over time
- **Resource Efficiency**: Lower memory and CPU usage

### **Business Benefits**
- **Near Real-time**: Faster data refresh cycles
- **Reliability**: Smaller processing windows = fewer failures
- **Operational**: Reduced maintenance overhead
- **Analytics**: More frequent data updates for better insights

## 🔄 Incremental Strategies

### **1. Append Strategy (Default)**
```sql
{{ config(
    materialized='incremental',
    unique_key='id'
) }}

-- Only adds new rows, doesn't update existing ones
-- Best for: Event logs, transactions, time-series data
```

### **2. Merge Strategy**
```sql
{{ config(
    materialized='incremental',
    unique_key='id',
    incremental_strategy='merge'
) }}

-- Updates existing rows and adds new ones
-- Best for: SCD Type 1, customer profiles, asset information
```

### **3. Delete+Insert Strategy**
```sql
{{ config(
    materialized='incremental',
    unique_key='id',
    incremental_strategy='delete+insert'
) }}

-- Deletes matching rows and inserts fresh data
-- Best for: Complex aggregations, calculated metrics
```

## 📊 Model-Specific Implementation

### **Price Data (Append-Only)**
```sql
-- stg_close_prices_incremental.sql
{{
  config(
    materialized='incremental',
    unique_key='isin || price_date'  -- Composite key
  )
}}

{% if is_incremental() %}
    where timestamp > (select max(price_date) from {{ this }})
{% endif %}
```

**Why Append-Only?**
- Price data is immutable once recorded
- No updates to historical prices
- Simple and fast processing

### **Transaction Data (Merge Strategy)**
```sql
-- stg_transactions_incremental.sql
{{
  config(
    materialized='incremental',
    unique_key='transaction_id',
    incremental_strategy='merge'
  )
}}

{% if is_incremental() %}
    where timestamp > (select max(transaction_date) from {{ this }})
{% endif %}
```

**Why Merge?**
- Transactions might get updated (corrections, cancellations)
- Need to handle late-arriving data
- Ensures data consistency

### **Performance Metrics (Delete+Insert)**
```sql
-- mart_asset_performance_incremental.sql
{{
  config(
    materialized='incremental',
    unique_key='isin',
    incremental_strategy='delete+insert'
  )
}}

{% if is_incremental() %}
    -- Recalculate for assets with new data
    where isin in (select distinct isin from new_data)
{% endif %}
```

**Why Delete+Insert?**
- Performance metrics depend on historical data
- Need complete recalculation when new data arrives
- Ensures accuracy of aggregated metrics

## ⚙️ Configuration Options

### **Unique Keys**
```sql
-- Single column
unique_key='transaction_id'

-- Multiple columns
unique_key=['isin', 'price_date']

-- Composite key expression
unique_key='isin || price_date'
```

### **Schema Change Handling**
```sql
-- Fail on schema changes (strict)
on_schema_change='fail'

-- Sync all columns (flexible)
on_schema_change='sync_all_columns'

-- Append new columns only
on_schema_change='append_new_columns'
```

### **Performance Optimizations**
```sql
-- Clustering for better query performance
cluster_by=['asset_category', 'sector']

-- Partitioning (Snowflake automatic)
-- Snowflake handles micro-partitions automatically
```

## 🎮 Incremental Execution Commands

### **Regular Incremental Run**
```bash
# Run only incremental models
dbt run --select config.materialized:incremental

# Run specific incremental model
dbt run --select stg_close_prices_incremental
```

### **Full Refresh When Needed**
```bash
# Full refresh all incremental models
dbt run --full-refresh --select config.materialized:incremental

# Full refresh specific model
dbt run --full-refresh --select mart_asset_performance_incremental
```

### **Selective Refresh**
```bash
# Refresh models downstream of a specific model
dbt run --select stg_close_prices_incremental+

# Refresh models upstream of a specific model
dbt run --select +mart_asset_performance_incremental
```

## 📈 Implementation Strategy

### **Phase 1: High-Volume Tables**
Start with tables that have the most data:
1. **close_prices** (~703K records) → `stg_close_prices_incremental`
2. **transactions** (~388K records) → `stg_transactions_incremental`

### **Phase 2: Calculated Metrics**
Add incremental logic to aggregated models:
1. **int_asset_daily_metrics** → `int_asset_daily_metrics_incremental`
2. **mart_asset_performance** → `mart_asset_performance_incremental`

### **Phase 3: Customer Analytics**
Implement for customer-related models:
1. **mart_customer_portfolio** → Customer portfolio updates
2. **int_customer_transactions** → Transaction enrichment

## ⚡ Performance Comparison

### **Full Refresh vs Incremental**
| Metric | Full Refresh | Incremental | Improvement |
|--------|-------------|-------------|-------------|
| **Runtime** | 10-30 minutes | 1-3 minutes | 10x faster |
| **Compute Cost** | $10-30 | $1-3 | 10x cheaper |
| **Data Processed** | 1M+ rows | 1K-10K rows | 100x less |
| **Warehouse Usage** | High | Low | 90% reduction |

## 🔧 Best Practices

### **1. Incremental Conditions**
```sql
{% if is_incremental() %}
    -- Time-based filtering
    where created_at > (select max(created_at) from {{ this }})
    
    -- Date-based filtering
    where date_column >= (select dateadd('day', -1, max(date_column)) from {{ this }})
    
    -- Complex conditions
    where updated_at > (select max(last_updated) from {{ this }})
       or status = 'PENDING'
{% endif %}
```

### **2. Unique Key Selection**
```sql
-- Good: Natural business key
unique_key='transaction_id'

-- Good: Composite key for time series
unique_key=['isin', 'price_date']

-- Avoid: Non-unique or frequently changing keys
unique_key='customer_name'  -- BAD: not unique
```

### **3. Error Handling**
```sql
-- Handle edge cases
{% if is_incremental() %}
    where timestamp > coalesce(
        (select max(price_date) from {{ this }}), 
        '1900-01-01'::timestamp
    )
{% endif %}
```

## 📅 Scheduling Strategy

### **Daily Incremental Runs**
```sql
-- Create scheduled task for daily incremental refresh
CREATE OR REPLACE TASK dbt_daily_incremental
  WAREHOUSE = FAR_TRANS_WH
  SCHEDULE = 'USING CRON 0 6 * * * UTC'  -- 6 AM UTC daily
AS
  EXECUTE DBT PROJECT dbt_investment_far_trans 
  COMMAND = 'dbt run --select config.materialized:incremental';
```

### **Weekly Full Refresh**
```sql
-- Create scheduled task for weekly full refresh
CREATE OR REPLACE TASK dbt_weekly_full_refresh
  WAREHOUSE = FAR_TRANS_WH
  SCHEDULE = 'USING CRON 0 2 * * 0 UTC'  -- 2 AM UTC on Sundays
AS
  EXECUTE DBT PROJECT dbt_investment_far_trans 
  COMMAND = 'dbt run --full-refresh --select config.materialized:incremental';
```

## 🚨 Common Pitfalls & Solutions

### **1. Missing Data on First Run**
```sql
-- Solution: Always handle initial load
{% if is_incremental() %}
    where timestamp > (select coalesce(max(price_date), '1900-01-01') from {{ this }})
{% endif %}
```

### **2. Late-Arriving Data**
```sql
-- Solution: Use lookback window
{% if is_incremental() %}
    where timestamp >= (select dateadd('day', -2, max(price_date)) from {{ this }})
{% endif %}
```

### **3. Schema Evolution**
```sql
-- Solution: Use sync_all_columns
{{ config(on_schema_change='sync_all_columns') }}
```

## 📊 Monitoring Incremental Models

### **Check Incremental Performance**
```sql
-- Monitor incremental run statistics
SELECT 
    table_name,
    rows_inserted,
    rows_updated,
    rows_deleted,
    execution_time
FROM INFORMATION_SCHEMA.COPY_HISTORY
WHERE table_name LIKE '%_incremental%'
ORDER BY start_time DESC;
```

### **Validate Data Completeness**
```sql
-- Compare incremental vs full refresh counts
SELECT 
    'incremental' as model_type,
    count(*) as row_count
FROM staging.stg_close_prices_incremental

UNION ALL

SELECT 
    'full_refresh' as model_type,
    count(*) as row_count
FROM staging.stg_close_prices;
```

## 🎯 Implementation Roadmap

### **Week 1: Setup**
- Implement incremental models for high-volume tables
- Test with small datasets
- Validate data consistency

### **Week 2: Production**
- Deploy incremental models to production
- Set up monitoring and alerting
- Create automated schedules

### **Week 3: Optimization**
- Fine-tune incremental conditions
- Optimize clustering and partitioning
- Monitor performance improvements

This incremental approach will dramatically improve your DBT project's performance and reduce operational costs!

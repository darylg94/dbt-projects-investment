# DBT Investment Analytics Project (FAR-Trans)

A comprehensive DBT project for transforming financial asset and customer data into analytics-ready models for investment analysis and portfolio management.

## 📋 Table of Contents
- [Overview](#overview)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Data Sources](#data-sources)
- [Models](#models)
- [Setup Instructions](#setup-instructions)
- [Usage](#usage)
- [Business Use Cases](#business-use-cases)
- [Testing](#testing)
- [Contributing](#contributing)

## 🎯 Overview

This DBT project transforms raw financial data into structured, analytics-ready models that enable:
- Asset performance analysis and risk assessment
- Customer portfolio analytics and segmentation
- Transaction pattern analysis
- Investment decision support

### Key Features
- **Modular Design**: Organized into staging, intermediate, and mart layers
- **Data Quality**: Comprehensive testing framework
- **SCD Type 2**: Historical tracking for assets and customers
- **Performance Metrics**: Daily returns, volatility, and risk calculations

## 🏗️ Architecture

### High-Level Architecture
```
┌─────────────────┐     ┌──────────────────┐     ┌──────────────────┐     ┌────────────────┐
│   Source Data   │     │   Raw Layer      │     │   DBT Pipeline   │     │ Analytics Layer│
│   CSV Files     │ ──> │   (Snowflake)    │ ──> │  Transformations │ ──> │   (Snowflake)  │
└─────────────────┘     └──────────────────┘     └──────────────────┘     └────────────────┘
```

### Detailed Data Flow
```
Source Files                 Raw Tables                DBT Models                  Final Marts
┌─────────────┐        ┌─────────────────┐      ┌──────────────────┐      ┌─────────────────┐
│asset_info.csv│───┐   │                 │      │   Staging Layer   │      │Asset Performance│
└─────────────┘   │   │raw.asset_info   │      │ ┌──────────────┐ │      │  ┌───────────┐  │
                  ├──>│                 │──────>│ │stg_asset_info│ │      │  │Daily Stats │  │
┌─────────────┐   │   │                 │      │ └──────────────┘ │      │  │Risk Metrics│  │
│close_prices │───┤   │raw.close_prices │      │        │        │      │  └───────────┘  │
└─────────────┘   │   │                 │      │        ▼        │      │        ▲        │
                  │   │                 │      │ ┌──────────────┐ │      │        │        │
┌─────────────┐   │   │raw.customer_info│      │ │int_daily_    │──────┘        │        │
│customer_info│───┤   │                 │      │ │  metrics     │ │               │        │
└─────────────┘   │   │                 │      │ └──────────────┘ │               │        │
                  │   │                 │      │        │        │      ┌────────┴────────┐
┌─────────────┐   │   │raw.transactions │      │        ▼        │      │   Customer      │
│transactions │───┘   │                 │      │ ┌──────────────┐ │      │   Portfolio     │
└─────────────┘       └─────────────────┘      │ │int_customer_ │──────>│  ┌──────────┐ │
                                               │ │transactions  │ │      │  │Analytics  │ │
                                               │ └──────────────┘ │      │  │Insights   │ │
                                               └──────────────────┘      │  └──────────┘ │
                                                                        └───────────────┘
```

### Snowflake Environment Architecture
```
┌─────────────────────────────────────────────────────────────────────┐
│                        Snowflake Environment                         │
│  ┌─────────────────────────────────────────────────────────────────┐ │
│  │                    FAR_TRANS_DB Database                        │ │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────┐ │ │
│  │  │ RAW Schema  │  │STAGING      │  │INTERMEDIATE │  │ MARTS   │ │ │
│  │  │   Tables    │─>│  Views      │─>│   Tables    │─>│ Tables  │ │ │
│  │  │             │  │             │  │             │  │         │ │ │
│  │  └─────────────┘  └─────────────┘  └─────────────┘  └─────────┘ │ │
│  └─────────────────────────────────────────────────────────────────┘ │
│                                                                       │
│  ┌─────────────────────┐    ┌──────────────────┐                     │
│  │    FAR_TRANS_WH     │    │  Security Model  │                     │
│  │    (Warehouse)      │    │  - DBT Role      │                     │
│  │    - XSMALL         │    │  - User Grants   │                     │
│  │    - Auto-suspend   │    │  - Schema Privs  │                     │
│  └─────────────────────┘    └──────────────────┘                     │
└─────────────────────────────────────────────────────────────────────┘
```

### DBT Model Dependencies
```
Raw Sources                    Staging Models              Intermediate Models           Mart Models
┌─────────────────┐           ┌─────────────────┐         ┌─────────────────┐         ┌─────────────────┐
│ asset_info      │──────────>│ stg_asset_info  │─────┐   │                 │         │                 │
└─────────────────┘           └─────────────────┘     │   │                 │         │                 │
                                                      ├──>│ int_asset_daily │────────>│ mart_asset_     │
┌─────────────────┐           ┌─────────────────┐     │   │ _metrics        │         │ performance     │
│ close_prices    │──────────>│ stg_close_prices│─────┘   │                 │         │                 │
└─────────────────┘           └─────────────────┘         └─────────────────┘         └─────────────────┘

┌─────────────────┐           ┌─────────────────┐         ┌─────────────────┐         ┌─────────────────┐
│ customer_info   │──────────>│ stg_customer_   │─────┐   │                 │         │                 │
└─────────────────┘           │ information     │     │   │                 │         │                 │
                              └─────────────────┘     ├──>│ int_customer_   │────────>│ mart_customer_  │
┌─────────────────┐           ┌─────────────────┐     │   │ transactions    │         │ portfolio       │
│ transactions    │──────────>│ stg_transactions│─────┘   │                 │         │                 │
└─────────────────┘           └─────────────────┘         └─────────────────┘         └─────────────────┘
```

### Data Transformation Flow
```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                                Data Transformation Layers                            │
├─────────────────────────────────────────────────────────────────────────────────────┤
│ Raw Data Layer                                                                      │
│ ├── Input Validation          ├── Data Type Casting       ├── Basic Cleaning       │
│ ├── CSV File Ingestion        ├── Null Handling           ├── Duplicate Removal    │
│ └── Error Handling            └── Format Standardization  └── Initial Quality Checks│
├─────────────────────────────────────────────────────────────────────────────────────┤
│ Staging Layer (Views)                                                               │
│ ├── Column Renaming           ├── Data Type Conversions   ├── SCD Type 2 Tracking  │
│ ├── Field Standardization     ├── Business Key Creation   ├── Audit Columns        │
│ └── Source System Mapping     └── Reference Data Joins    └── Data Lineage         │
├─────────────────────────────────────────────────────────────────────────────────────┤
│ Intermediate Layer (Tables)                                                         │
│ ├── Business Logic            ├── Complex Calculations    ├── Data Enrichments     │
│ ├── Multi-table Joins         ├── Aggregations           ├── Derived Metrics      │
│ └── Performance Optimization  └── Window Functions        └── Business Rules       │
├─────────────────────────────────────────────────────────────────────────────────────┤
│ Mart Layer (Tables)                                                                 │
│ ├── Final Aggregations        ├── Business Metrics       ├── Analytics-Ready Views│
│ ├── KPI Calculations          ├── Dimensional Modeling    ├── Report-Ready Data    │
│ └── Performance Tuning        └── User-Friendly Naming    └── Documentation        │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

### Security & Access Control Architecture
```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  User: dgoh     │     │  FAR_TRANS_     │     │   Schema-Level  │
│                 │────>│  DBT_ROLE       │────>│   Permissions   │
│                 │     │                 │     │                 │
└─────────────────┘     └─────────────────┘     └─────────────────┘
                              │                           │
                              ▼                           ▼
                        ┌─────────────────┐     ┌─────────────────┐
                        │   Warehouse     │     │   Table/View    │
                        │   Access        │     │   Privileges    │
                        │   (FAR_TRANS_WH)│     │   (CRUD)        │
                        └─────────────────┘     └─────────────────┘

Access Control Matrix:
┌──────────────┬─────────┬─────────────┬──────────────┬─────────┐
│   Schema     │  READ   │   WRITE     │   CREATE     │  DROP   │
├──────────────┼─────────┼─────────────┼──────────────┼─────────┤
│ RAW          │   ✓     │      ✗      │      ✗       │    ✗    │
│ STAGING      │   ✓     │      ✓      │      ✓       │    ✓    │
│ INTERMEDIATE │   ✓     │      ✓      │      ✓       │    ✓    │
│ MARTS        │   ✓     │      ✓      │      ✓       │    ✓    │
└──────────────┴─────────┴─────────────┴──────────────┴─────────┘
```

### Testing Framework Architecture
```
┌─────────────────────────────────────────────────────────────────────┐
│                         Testing Strategy                             │
├─────────────────────────────────────────────────────────────────────┤
│ Source Data Tests                                                   │
│ ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐ │
│ │ Not Null    │  │ Uniqueness  │  │Relationships│  │Accepted Vals│ │
│ │ Tests       │  │ Constraints │  │ Integrity   │  │ Validation  │ │
│ └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘ │
├─────────────────────────────────────────────────────────────────────┤
│ Transformation Tests                                                │
│ ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐ │
│ │ Generic     │  │ Custom      │  │ Business    │  │ Performance │ │
│ │ Tests       │  │ Assertions  │  │ Rules       │  │ Tests       │ │
│ └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘ │
├─────────────────────────────────────────────────────────────────────┤
│ Business Logic Tests                                                │
│ ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐ │
│ │ Price       │  │ Customer    │  │ Portfolio   │  │ Risk        │ │
│ │ Validation  │  │ Consistency │  │ Balance     │  │ Metrics     │ │
│ └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
```

## 📁 Project Structure

```
dbt-projects-on-snowflake/
├── models/
│   ├── staging/                 # Raw data standardization
│   │   ├── stg_asset_information.sql
│   │   ├── stg_close_prices.sql
│   │   ├── stg_customer_information.sql
│   │   ├── stg_transactions.sql
│   │   └── schema.yml
│   ├── intermediate/            # Business logic transformations
│   │   ├── int_asset_daily_metrics.sql
│   │   └── int_customer_transactions.sql
│   └── marts/                   # Business-ready analytics models
│       ├── mart_asset_performance.sql
│       └── mart_customer_portfolio.sql
├── tests/
│   ├── generic/                 # Reusable test definitions
│   └── singular/                # Specific business rule tests
├── FAR-Trans/                   # Source CSV files
│   ├── asset_information.csv
│   ├── close_prices.csv
│   ├── customer_information.csv
│   └── transactions.csv
├── dbt_project.yml              # Project configuration
├── profiles.yml                 # Connection configuration
├── packages.yml                 # Dependencies
└── setup.sql                    # Snowflake environment setup
```

## 📊 Data Sources

### Core Tables
| Table | Description | Records | Key Fields |
|-------|-------------|---------|------------|
| `asset_information` | Financial instrument reference data | ~837 | ISIN, assetName, assetCategory, sector |
| `close_prices` | Daily closing prices | ~703K | ISIN, timestamp, closePrice |
| `customer_information` | Customer profiles and risk data | ~32K | customerID, customerType, riskLevel |
| `transactions` | Customer trading activity | ~388K | transactionID, customerID, ISIN, totalValue |

## 🏗️ Models

### Staging Models
Clean and standardize raw data with minimal transformations:
- **`stg_asset_information`**: Asset reference data with SCD Type 2 tracking
- **`stg_close_prices`**: Daily price data with proper typing
- **`stg_customer_information`**: Customer profiles with historical tracking
- **`stg_transactions`**: Transaction data with standardized fields

### Intermediate Models
Business logic and enrichment:
- **`int_asset_daily_metrics`**: Daily returns, price changes, and asset metadata
- **`int_customer_transactions`**: Enriched transactions with customer and asset context

### Mart Models
Analytics-ready business models:
- **`mart_asset_performance`**: Asset performance metrics, volatility, and statistics
- **`mart_customer_portfolio`**: Customer portfolio summaries and trading patterns

## 🚀 Setup Instructions

### Prerequisites
- Snowflake account with ACCOUNTADMIN privileges
- DBT installed (`pip install dbt-snowflake`)
- Python 3.8+

### 1. Environment Setup
```bash
# Clone the repository
git clone <repository-url>
cd dbt-projects-on-snowflake

# Install dependencies
pip install dbt-snowflake
```

### 2. Snowflake Setup
```sql
-- Run setup.sql in Snowflake to create:
-- - Database: FAR_TRANS_DB
-- - Schemas: RAW, STAGING, INTERMEDIATE, MARTS
-- - Warehouse: FAR_TRANS_WH
-- - Load CSV data
```

### 3. Configure Connection
Update `profiles.yml` with your Snowflake credentials:
```yaml
dbt_investment_FAR_TRANS:
  target: dev
  outputs:
    dev:
      type: snowflake
      account: your_account_id
      user: your_username
      password: your_password
      role: FAR_TRANS_DBT_ROLE
      database: FAR_TRANS_DB
      warehouse: FAR_TRANS_WH
      schema: RAW
```

### 4. Install DBT Dependencies
```bash
dbt deps
```

### 5. Test Connection
```bash
dbt debug
```

## 💻 Usage

### Run All Models
```bash
dbt run
```

### Run Specific Model Layers
```bash
# Staging models only
dbt run --select staging

# Marts only
dbt run --select marts

# Specific model
dbt run --select mart_asset_performance
```

### Run Tests
```bash
# All tests
dbt test

# Source tests only
dbt test --select source:*

# Model tests only
dbt test --select mart_asset_performance
```

### Generate Documentation
```bash
dbt docs generate
dbt docs serve
```

## 📈 Business Use Cases

### 1. Asset Performance Analysis
- **Daily Returns**: Track asset performance over time
- **Volatility Analysis**: Measure risk through price volatility
- **Sector Comparison**: Compare performance across industries
- **Price Trends**: Identify trending assets and market patterns

```sql
-- Example: Top performing assets by sector
SELECT 
    sector,
    asset_name,
    avg_daily_return,
    daily_volatility
FROM mart_asset_performance
WHERE trading_days > 100
ORDER BY avg_daily_return DESC;
```

### 2. Customer Portfolio Management
- **Portfolio Diversification**: Analyze customer asset allocation
- **Risk Assessment**: Match customer risk profiles with investments
- **Trading Patterns**: Identify customer behavior and preferences
- **Revenue Analysis**: Track customer value and transaction volumes

```sql
-- Example: Customer portfolio summary
SELECT 
    customer_type,
    risk_level,
    AVG(net_investment) as avg_portfolio_value,
    AVG(unique_assets) as avg_diversification
FROM mart_customer_portfolio
GROUP BY customer_type, risk_level;
```

### 3. Risk Management
- **Customer Suitability**: Ensure investments match risk tolerance
- **Market Risk**: Monitor portfolio exposure and concentration
- **Performance Attribution**: Analyze returns by asset class and sector

## 🧪 Testing

### Data Quality Tests
- **Source Data**: Not null, unique, and referential integrity
- **Business Rules**: Valid risk levels, positive prices, transaction consistency
- **Custom Tests**: Daily price change validation, customer risk alignment

### Test Categories
```bash
# Source data validation
dbt test --select source:raw

# Generic tests (not_null, unique, etc.)
dbt test --select test_type:generic

# Custom business rule tests
dbt test --select test_type:singular
```

## 📋 Key Metrics & KPIs

### Asset Metrics
- Average daily return
- Volatility (standard deviation)
- Price range (min/max)
- Trading days count
- Sharpe ratio components

### Customer Metrics
- Portfolio value distribution
- Asset diversification
- Transaction frequency
- Risk profile alignment
- Customer lifetime value

## 🔧 Configuration

### Model Materialization
- **Staging**: Views (real-time data access)
- **Intermediate**: Tables (optimized for complex joins)
- **Marts**: Tables (fast query performance)

### Schema Organization
- **RAW**: Source data (read-only)
- **STAGING**: Standardized views
- **INTERMEDIATE**: Business logic tables
- **MARTS**: Analytics-ready tables

## 🤝 Contributing

1. **Create Feature Branch**: `git checkout -b feature/new-analysis`
2. **Add Models**: Follow the staging → intermediate → marts pattern
3. **Add Tests**: Include data quality and business rule tests
4. **Update Documentation**: Add model descriptions and business context
5. **Submit PR**: Include test results and documentation updates

### Development Guidelines
- Use clear, descriptive model names
- Add comprehensive tests for new models
- Document business logic and assumptions
- Follow SQL style guide (SELECT, FROM, WHERE order)
- Use meaningful column aliases

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 📞 Support

For questions or issues:
- Create an issue in the repository
- Review the DBT documentation: https://docs.getdbt.com/
- Check Snowflake documentation: https://docs.snowflake.com/

---

**Built with ❤️ using DBT and Snowflake**

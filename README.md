# FAR-Trans DBT Project

This DBT project transforms financial asset and customer data into analytics-ready models for investment analysis and customer profiling.

## Project Structure

```
models/
├── staging/           # Raw data models with minimal transformations
├── intermediate/      # Transformed and enriched data models
├── marts/            # Business-specific data models
└── utils/            # Reusable macros and utilities
```

## Models Overview

### Staging Models
- `stg_asset_information`: Asset reference data with SCD Type 2 tracking
- `stg_close_prices`: Daily closing prices for financial instruments
- `stg_customer_information`: Customer profiles with SCD Type 2 tracking

### Intermediate Models
- `int_asset_daily_metrics`: Daily price metrics and returns calculations
- `int_customer_risk_profile`: Enhanced customer risk profiling

### Mart Models
- `mart_asset_performance`: Asset performance analytics and statistics
- `mart_customer_investment_profile`: Customer segmentation and investment capacity analysis

## Usage

1. Update the profile in `dbt_project.yml` to match your Snowflake connection
2. Configure source database and schema in `models/staging/schema.yml`
3. Run the following commands:
   ```bash
   dbt deps
   dbt seed
   dbt run
   dbt test
   ```

## Data Sources

The project uses three main data sources:
1. Asset Information: Reference data for financial instruments
2. Close Prices: Daily closing prices for assets
3. Customer Information: Customer profiles and risk assessments

## Business Use Cases

1. Asset Performance Analysis
   - Track asset performance metrics
   - Calculate risk metrics (volatility, returns)
   - Analyze trends by asset category and sector

2. Customer Profiling
   - Segment customers by risk tolerance
   - Analyze investment capacity distribution
   - Track changes in customer risk profiles

## Testing

The project includes the following tests:
- Source data validation
- Referential integrity checks
- Not null constraints
- Unique key validation

## Contributing

1. Create a new branch for your changes
2. Follow the existing code structure
3. Add appropriate tests
4. Update documentation
5. Submit a pull request

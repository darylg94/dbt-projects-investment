# FAR-Trans DBT Project Architecture

## High-Level Architecture
```
┌─────────────────┐     ┌──────────────────┐     ┌──────────────────┐     ┌────────────────┐
│   Source Data   │     │   Raw Layer      │     │   DBT Pipeline   │     │ Analytics Layer│
│   CSV Files     │ ──> │   (Snowflake)    │ ──> │  Transformations │ ──> │   (Snowflake)  │
└─────────────────┘     └──────────────────┘     └──────────────────┘     └────────────────┘
```

## Detailed Data Flow
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
┌─────────────┐   │   │raw.customer_info│      │ │int_daily_metrics│──────┘        │        │
│customer_info│───┘   │                 │      │ └──────────────┘ │               │        │
└─────────────┘       └─────────────────┘      │        │        │      ┌────────┴────────┐
                                               │        ▼        │      │   Customer      │
                                               │ ┌──────────────┐ │      │   Profiles     │
                                               │ │int_risk_profile│──────>│  ┌──────────┐ │
                                               │ └──────────────┘ │      │  │Segments   │ │
                                               └──────────────────┘      │  │Risk Levels│ │
                                                                        │  └──────────┘ │
                                                                        └───────────────┘
```

## Component Architecture
```
┌─────────────────────────────────────────────────────────────────────┐
│                        Snowflake Environment                         │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐            │
│  │  FAR_TRANS_DB                                      │            │
│  │  ├── RAW Schema   │    │ STAGING Schema│    │ MARTS Schema │            │
│  │  │  Tables        │───>│  Views        │───>│  Tables      │            │
│  │  └───────────┘    └─────────────┘    └─────────────┘            │
│  │                                                                  │
│  │  ┌─────────────────────┐    ┌──────────────────┐               │
│  │  │    FAR_TRANS_WH     │    │  DBT_ROLE        │               │
│  │  │    (Warehouse)      │    │  (Permissions)    │               │
│  │  └─────────────────────┘    └──────────────────┘               │
└─────────────────────────────────────────────────────────────────────┘
```

## DBT Model Dependencies
```
stg_asset_information     stg_close_prices     stg_customer_information
         │                      │                       │
         └──────────┐    ┌─────┘                       │
                    ▼    ▼                             ▼
              int_asset_daily_metrics          int_customer_risk_profile
                    │                                   │
                    │                                   │
                    ▼                                   ▼
            mart_asset_performance        mart_customer_investment_profile
```

## Data Transformation Flow
```
Raw Data Layer
├── Input Validation
├── Data Type Casting
└── Basic Cleaning

Staging Layer (Views)
├── Column Renaming
├── Data Type Conversions
└── SCD Type 2 Tracking

Intermediate Layer (Tables)
├── Business Logic
├── Calculations
└── Enrichments

Mart Layer (Tables)
├── Aggregations
├── Business Metrics
└── Analytics-Ready Views
```

## Security Architecture
```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  FAR_TRANS_     │     │  FAR_TRANS_     │     │   Schema-Level  │
│  DBT_USER       │────>│  DBT_ROLE       │────>│   Permissions   │
└─────────────────┘     └─────────────────┘     └─────────────────┘
                              │
                              ▼
                        ┌─────────────────┐
                        │   Warehouse     │
                        │   Access        │
                        └─────────────────┘
```

## Testing Framework
```
Data Quality Tests
├── Schema Tests
│   ├── Not Null
│   ├── Unique
│   └── Relationships
└── Custom Tests
    ├── Business Rules
    └── Data Validation

┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Source     │     │  Transform   │     │  Target     │
│  Tests      │────>│  Tests      │────>│  Tests      │
└─────────────┘     └─────────────┘     └─────────────┘
```

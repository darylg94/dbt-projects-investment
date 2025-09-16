# Previous setup content remains the same until the table creation section

-- Create additional tables for raw data
CREATE OR REPLACE TABLE raw.limit_prices (
    isin VARCHAR(12),
    timestamp TIMESTAMP,
    upper_limit DECIMAL(20,4),
    lower_limit DECIMAL(20,4),
    currency VARCHAR(3)
);

CREATE OR REPLACE TABLE raw.markets (
    market_id VARCHAR(50),
    market_name VARCHAR(100),
    country VARCHAR(50),
    timezone VARCHAR(50),
    opening_time TIME,
    closing_time TIME,
    currency VARCHAR(3),
    is_active BOOLEAN,
    valid_from TIMESTAMP
);

CREATE OR REPLACE TABLE raw.questionnaire (
    questionnaire_id VARCHAR(50),
    customer_id VARCHAR(50),
    submission_date TIMESTAMP,
    investment_horizon VARCHAR(50),
    risk_tolerance_score INTEGER,
    investment_knowledge INTEGER,
    income_bracket VARCHAR(50),
    investment_goal VARCHAR(100),
    loss_tolerance DECIMAL(5,2),
    preferred_investment_types VARCHAR(500),
    timestamp TIMESTAMP
);

-- Load data from CSV files
PUT file:///Users/dgoh/Desktop/projects/sf-quickstarts/dbt-projects-on-snowflake/FAR-Trans/limit_prices.csv @far_trans_stage;
PUT file:///Users/dgoh/Desktop/projects/sf-quickstarts/dbt-projects-on-snowflake/FAR-Trans/markets.csv @far_trans_stage;
PUT file:///Users/dgoh/Desktop/projects/sf-quickstarts/dbt-projects-on-snowflake/FAR-Trans/questionnaire.csv @far_trans_stage;

-- Copy data from stage to tables
COPY INTO raw.limit_prices
FROM @far_trans_stage/limit_prices.csv
FILE_FORMAT = csv_format
ON_ERROR = CONTINUE;

COPY INTO raw.markets
FROM @far_trans_stage/markets.csv
FILE_FORMAT = csv_format
ON_ERROR = CONTINUE;

COPY INTO raw.questionnaire
FROM @far_trans_stage/questionnaire.csv
FILE_FORMAT = csv_format
ON_ERROR = CONTINUE;

-- Rest of the setup script remains the same
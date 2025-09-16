-- Setup Snowflake Environment
USE ROLE ACCOUNTADMIN;

-- Create Database and Schemas
CREATE DATABASE IF NOT EXISTS FAR_TRANS_DB;
USE DATABASE FAR_TRANS_DB;

-- Create Raw Schema for source data
CREATE SCHEMA IF NOT EXISTS RAW;

-- Create Schemas for DBT
CREATE SCHEMA IF NOT EXISTS STAGING;
CREATE SCHEMA IF NOT EXISTS INTERMEDIATE;
CREATE SCHEMA IF NOT EXISTS MARTS;

-- Create warehouse if it doesn't exist
CREATE WAREHOUSE IF NOT EXISTS FAR_TRANS_WH 
    WAREHOUSE_SIZE = 'XSMALL' 
    AUTO_SUSPEND = 300 
    AUTO_RESUME = TRUE;

USE WAREHOUSE FAR_TRANS_WH;
USE SCHEMA RAW;

-- Create file format for CSV files
CREATE OR REPLACE FILE FORMAT csv_format
    TYPE = CSV
    FIELD_DELIMITER = ','
    SKIP_HEADER = 1
    NULL_IF = ('NULL', 'null')
    EMPTY_FIELD_AS_NULL = TRUE;

-- Create stages for data loading
CREATE OR REPLACE STAGE far_trans_stage
    FILE_FORMAT = csv_format;

-- Create tables for raw data
CREATE OR REPLACE TABLE raw.asset_information (
    isin VARCHAR(12),
    assetName VARCHAR(255),
    assetShortName VARCHAR(50),
    assetCategory VARCHAR(50),
    assetSubCategory VARCHAR(50),
    marketID VARCHAR(50),
    sector VARCHAR(100),
    industry VARCHAR(100),
    timestamp TIMESTAMP
);

CREATE OR REPLACE TABLE raw.close_prices (
    isin VARCHAR(12),
    timestamp TIMESTAMP,
    closePrice DECIMAL(20,4)
);

CREATE OR REPLACE TABLE raw.customer_information (
    customerID VARCHAR(50),
    customerType VARCHAR(50),
    riskLevel VARCHAR(50),
    investmentCapacity VARCHAR(50),
    lastQuestionnaireDate DATE,
    timestamp TIMESTAMP
);

-- Load data from CSV files
-- Note: Replace <your_stage_path> with actual path where CSV files are stored
PUT file:///Users/dgoh/Desktop/projects/sf-quickstarts/dbt-projects-on-snowflake/FAR-Trans/asset_information.csv @far_trans_stage;
PUT file:///Users/dgoh/Desktop/projects/sf-quickstarts/dbt-projects-on-snowflake/FAR-Trans/close_prices.csv @far_trans_stage;
PUT file:///Users/dgoh/Desktop/projects/sf-quickstarts/dbt-projects-on-snowflake/FAR-Trans/customer_information.csv @far_trans_stage;

-- Copy data from stage to tables
COPY INTO raw.asset_information
FROM @far_trans_stage/asset_information.csv
FILE_FORMAT = csv_format
ON_ERROR = CONTINUE;

COPY INTO raw.close_prices
FROM @far_trans_stage/close_prices.csv
FILE_FORMAT = csv_format
ON_ERROR = CONTINUE;

COPY INTO raw.customer_information
FROM @far_trans_stage/customer_information.csv
FILE_FORMAT = csv_format
ON_ERROR = CONTINUE;

-- Create a dedicated role for DBT
CREATE ROLE IF NOT EXISTS FAR_TRANS_DBT_ROLE;

-- Grant privileges to DBT role
GRANT USAGE ON DATABASE FAR_TRANS_DB TO ROLE FAR_TRANS_DBT_ROLE;
GRANT USAGE ON SCHEMA RAW TO ROLE FAR_TRANS_DBT_ROLE;
GRANT USAGE ON SCHEMA STAGING TO ROLE FAR_TRANS_DBT_ROLE;
GRANT USAGE ON SCHEMA INTERMEDIATE TO ROLE FAR_TRANS_DBT_ROLE;
GRANT USAGE ON SCHEMA MARTS TO ROLE FAR_TRANS_DBT_ROLE;

-- Grant read access to raw tables
GRANT SELECT ON ALL TABLES IN SCHEMA RAW TO ROLE FAR_TRANS_DBT_ROLE;

-- Grant write access to transformation schemas
GRANT CREATE TABLE, CREATE VIEW ON SCHEMA STAGING TO ROLE FAR_TRANS_DBT_ROLE;
GRANT CREATE TABLE, CREATE VIEW ON SCHEMA INTERMEDIATE TO ROLE FAR_TRANS_DBT_ROLE;
GRANT CREATE TABLE, CREATE VIEW ON SCHEMA MARTS TO ROLE FAR_TRANS_DBT_ROLE;

-- Grant warehouse usage
GRANT USAGE ON WAREHOUSE FAR_TRANS_WH TO ROLE FAR_TRANS_DBT_ROLE;

-- Create a technical user for DBT (if needed)
CREATE USER IF NOT EXISTS FAR_TRANS_DBT_USER
    PASSWORD = 'your_secure_password_here'
    DEFAULT_ROLE = FAR_TRANS_DBT_ROLE
    DEFAULT_WAREHOUSE = FAR_TRANS_WH;

GRANT ROLE FAR_TRANS_DBT_ROLE TO USER FAR_TRANS_DBT_USER;

-- Verify data loading
SELECT COUNT(*) FROM raw.asset_information;
SELECT COUNT(*) FROM raw.close_prices;
SELECT COUNT(*) FROM raw.customer_information;

-- Sample data verification queries
SELECT * FROM raw.asset_information LIMIT 5;
SELECT * FROM raw.close_prices LIMIT 5;
SELECT * FROM raw.customer_information LIMIT 5;

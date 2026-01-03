-- 02_generate_mock_data.sql
-- Purpose: Generate synthetic data for Banks and Insurers to simulate the problem scenario.

USE WAREHOUSE ANALYTICS_WH;

-- ==========================================
-- 1. BANK DATA (Transactions)
-- ==========================================
USE ROLE PROVIDER_BANK;
CREATE OR REPLACE SCHEMA BANK_DB.RAW;

CREATE OR REPLACE TABLE BANK_DB.RAW.TRANSACTIONS (
    TXN_ID VARCHAR(36),
    CUSTOMER_ID VARCHAR(20),
    TXN_DATE DATE,
    MERCHANT_CATEGORY VARCHAR(50),
    AMOUNT NUMBER(10, 2),
    IS_FRAUDULENT BOOLEAN
);

-- Generate 10,000 Transactions
INSERT INTO BANK_DB.RAW.TRANSACTIONS
SELECT 
    UUID_STRING(),
    'CUST_' || UNIFORM(1, 1000, RANDOM()), -- 1000 Unique Customers
    DATEADD(DAY, -UNIFORM(1, 365, RANDOM()), CURRENT_DATE()),
    ARRAY_CONSTRUCT('Retail', 'Travel', 'Dining', 'Electronics', 'Online_Services')[UNIFORM(0, 4, RANDOM())]::VARCHAR,
    UNIFORM(10, 5000, RANDOM()),
    CASE WHEN UNIFORM(1, 100, RANDOM()) <= 2 THEN TRUE ELSE FALSE END -- 2% Fraud Rate
FROM TABLE(GENERATOR(ROWCOUNT => 10000));

-- ==========================================
-- 2. INSURER DATA (Claims)
-- ==========================================
USE ROLE PROVIDER_INSURER;
CREATE OR REPLACE SCHEMA INSURER_DB.RAW;

CREATE OR REPLACE TABLE INSURER_DB.RAW.CLAIMS (
    CLAIM_ID VARCHAR(36),
    CUSTOMER_ID VARCHAR(20),
    CLAIM_DATE DATE,
    POLICY_TYPE VARCHAR(50),
    CLAIM_AMOUNT NUMBER(10, 2),
    STATUS VARCHAR(20)
);

-- Generate 5,000 Claims
INSERT INTO INSURER_DB.RAW.CLAIMS
SELECT 
    UUID_STRING(),
    'CUST_' || UNIFORM(1, 1000, RANDOM()), -- Same 1000 Customers ID space for overlap
    DATEADD(DAY, -UNIFORM(1, 365, RANDOM()), CURRENT_DATE()),
    ARRAY_CONSTRUCT('Auto', 'Home', 'Health', 'Life')[UNIFORM(0, 3, RANDOM())]::VARCHAR,
    UNIFORM(500, 50000, RANDOM()),
    ARRAY_CONSTRUCT('Approved', 'Rejected', 'Pending', 'Under_Review')[UNIFORM(0, 3, RANDOM())]::VARCHAR
FROM TABLE(GENERATOR(ROWCOUNT => 5000));

-- ==========================================
-- 3. SHARED DEMOGRAPHICS (Simulated "Third Party" or Reference Data)
-- This could also be owned by the Bank or Insurer, let's say Bank owns Customer Attributes.
-- ==========================================
USE ROLE PROVIDER_BANK;

CREATE OR REPLACE TABLE BANK_DB.RAW.CUSTOMERS (
    CUSTOMER_ID VARCHAR(20),
    AGE INT,
    REGION VARCHAR(50),
    INCOME_BRACKET VARCHAR(20),
    HAS_SUBSIDY BOOLEAN
);

-- Generate 1,000 Customers
INSERT INTO BANK_DB.RAW.CUSTOMERS
SELECT 
    'CUST_' || ROW_NUMBER() OVER (ORDER BY SEQ1()),
    UNIFORM(18, 90, RANDOM()),
    ARRAY_CONSTRUCT('North', 'South', 'East', 'West')[UNIFORM(0, 3, RANDOM())]::VARCHAR,
    ARRAY_CONSTRUCT('Low', 'Medium', 'High')[UNIFORM(0, 2, RANDOM())]::VARCHAR,
    CASE WHEN UNIFORM(1, 10, RANDOM()) > 7 THEN TRUE ELSE FALSE END -- 30% Subsidy
FROM TABLE(GENERATOR(ROWCOUNT => 1000));

SELECT 'Mock Data Generation Complete' as Status;

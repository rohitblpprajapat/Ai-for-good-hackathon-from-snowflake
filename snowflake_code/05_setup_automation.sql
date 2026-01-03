-- 05_setup_automation.sql
-- Purpose: Automate the generation of insights using Streams (CDC) and Tasks (Scheduler).

USE WAREHOUSE ANALYTICS_WH;
USE ROLE ACCOUNTADMIN;

-- ==========================================
-- 1. SETUP REPORTING TABLE (Destination)
-- ==========================================
CREATE OR REPLACE TABLE SHARED_ANALYSIS_ZONE.CLEANROOM.FRAUD_RISK_REPORT_HISTORY (
    REPORT_DATE TIMESTAMP,
    AGE_BUCKET VARCHAR,
    TOTAL_TXN_AMOUNT NUMBER,
    TOTAL_CLAIM_AMOUNT NUMBER,
    RISK_SCORE NUMBER
);

GRANT SELECT ON TABLE SHARED_ANALYSIS_ZONE.CLEANROOM.FRAUD_RISK_REPORT_HISTORY TO ROLE CONSUMER_ANALYST;

-- ==========================================
-- 2. SETUP STREAM (Input Trigger)
-- ==========================================
-- We want to trigger a report refresh whenever new transactions arrive.
USE ROLE PROVIDER_BANK;
CREATE OR REPLACE STREAM BANK_DB.RAW.TXN_STREAM ON TABLE BANK_DB.RAW.TRANSACTIONS;

-- Grant access to the stream to the AccountAdmin (simulating the system task runner)
GRANT SELECT ON STREAM BANK_DB.RAW.TXN_STREAM TO ROLE ACCOUNTADMIN;

-- ==========================================
-- 3. SETUP TASK (Orchestration)
-- ==========================================
USE ROLE ACCOUNTADMIN;

CREATE OR REPLACE TASK SHARED_ANALYSIS_ZONE.CLEANROOM.GENERATE_DAILY_REPORT_TASK
    WAREHOUSE = ANALYTICS_WH
    SCHEDULE = 'USING CRON 0 8 * * * UTC' -- Run daily at 8 AM
    WHEN SYSTEM$STREAM_HAS_DATA('BANK_DB.RAW.TXN_STREAM') -- Only run if new data exists
AS
    INSERT INTO SHARED_ANALYSIS_ZONE.CLEANROOM.FRAUD_RISK_REPORT_HISTORY
    SELECT 
        CURRENT_TIMESTAMP(),
        *
    FROM TABLE(SHARED_ANALYSIS_ZONE.CLEANROOM.ANALYZE_CROSS_INDUSTRY_FRAUD(18, 100));

-- Activate the Task
ALTER TASK SHARED_ANALYSIS_ZONE.CLEANROOM.GENERATE_DAILY_REPORT_TASK RESUME;

SELECT 'Automation Setup (Streams & Tasks) Complete' as Status;

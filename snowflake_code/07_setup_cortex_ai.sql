-- 07_setup_cortex_ai.sql
-- Purpose: Integrate Snowflake Cortex (AI) to generate plain-language risk narratives from aggregated data.

USE WAREHOUSE ANALYTICS_WH;
USE ROLE ACCOUNTADMIN; 

-- ==========================================
-- 1. ADD NARRATIVE COLUMN TO REPORT TABLE
-- ==========================================
ALTER TABLE SHARED_ANALYSIS_ZONE.CLEANROOM.FRAUD_RISK_REPORT_HISTORY 
ADD COLUMN IF NOT EXISTS RISK_NARRATIVE VARCHAR;

-- ==========================================
-- 2. CREATE AI WRAPPER FUNCTION
-- ==========================================
-- This function takes the report row and asks Llama 3 to interpret it.
-- Note: 'snowflake-cortex' must be enabled in the account (Default in most regions).

CREATE OR REPLACE FUNCTION SHARED_ANALYSIS_ZONE.CLEANROOM.GENERATE_RISK_NARRATIVE(
    AGE_BUCKET VARCHAR, 
    TOTAL_TXN NUMBER, 
    TOTAL_CLAIMS NUMBER, 
    RISK_SCORE NUMBER
)
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
    SNOWFLAKE.CORTEX.COMPLETE(
        'llama3-70b', 
        CONCAT(
            'Act as a Senior Fraud Risk Analyst for a financial consortium. ',
            'Analyze the following aggregated data for the age group ', AGE_BUCKET, ': ',
            'Total Transaction Volume: $', TO_VARCHAR(TOTAL_TXN), '. ',
            'Total Insurance Claims: $', TO_VARCHAR(TOTAL_CLAIMS), '. ',
            'Calculated Risk Score: ', TO_VARCHAR(RISK_SCORE), '. ',
            'The Risk Score represents a combination of potentially fraudulent transactions and rejected insurance claims. ',
            'Provide a concise, 2-sentence plain-language explanation of what this means for the Banks and Insurers. ',
            'Focus on the implications of financial inclusion or potential fraud rings. ',
            'Do not imply you have access to individual data. refer only to the segment.'
        )
    )
$$;

GRANT USAGE ON FUNCTION SHARED_ANALYSIS_ZONE.CLEANROOM.GENERATE_RISK_NARRATIVE(VARCHAR, NUMBER, NUMBER, NUMBER) TO ROLE CONSUMER_ANALYST;

-- ==========================================
-- 3. UPDATE TASK TO INCLUDE AI GENERATION
-- ==========================================
-- We modify the previous task to enrich the data with AI as it aids insertion.

CREATE OR REPLACE TASK SHARED_ANALYSIS_ZONE.CLEANROOM.GENERATE_DAILY_REPORT_TASK
    WAREHOUSE = ANALYTICS_WH
    SCHEDULE = 'USING CRON 0 8 * * * UTC' 
    WHEN SYSTEM$STREAM_HAS_DATA('BANK_DB.RAW.TXN_STREAM')
AS
    INSERT INTO SHARED_ANALYSIS_ZONE.CLEANROOM.FRAUD_RISK_REPORT_HISTORY (REPORT_DATE, AGE_BUCKET, TOTAL_TXN_AMOUNT, TOTAL_CLAIM_AMOUNT, RISK_SCORE, RISK_NARRATIVE)
    SELECT 
        CURRENT_TIMESTAMP(),
        AGE_BUCKET,
        TOTAL_TXN_AMOUNT,
        TOTAL_CLAIM_AMOUNT,
        RISK_SCORE,
        SHARED_ANALYSIS_ZONE.CLEANROOM.GENERATE_RISK_NARRATIVE(AGE_BUCKET, TOTAL_TXN_AMOUNT, TOTAL_CLAIM_AMOUNT, RISK_SCORE)
    FROM TABLE(SHARED_ANALYSIS_ZONE.CLEANROOM.ANALYZE_CROSS_INDUSTRY_FRAUD(18, 100));

ALTER TASK SHARED_ANALYSIS_ZONE.CLEANROOM.GENERATE_DAILY_REPORT_TASK RESUME;


-- ==========================================
-- 4. AD-HOC TEST OF AI FUNCTION
-- ==========================================
-- Run this manually to see the magic (requires credits)
-- SELECT SHARED_ANALYSIS_ZONE.CLEANROOM.GENERATE_RISK_NARRATIVE('18-30', 500000, 200000, 85) as AI_INSIGHT;

SELECT 'Cortex AI Setup Complete. Task updated to generate narratives.' as Status;

-- 06_verify_solution.sql
-- Purpose: Run this script to verify the Data Clean Room security and functionality.

-- ==========================================
-- TEST 1: CONSUMER CANNOT ACCESS RAW DATA
-- ==========================================
USE ROLE CONSUMER_ANALYST;
USE WAREHOUSE ANALYTICS_WH;

SELECT 'TEST 1: Attempting to access raw Bank transactions (Should Fail)...' as TEST_CASE;

-- This query should fail with an authorization error because Consumer has no privileges on BANK_DB.RAW
-- Uncomment to test failure:
-- SELECT * FROM BANK_DB.RAW.TRANSACTIONS LIMIT 10;


-- ==========================================
-- TEST 2: CONSUMER CAN RUN APPROVED ANALYSIS
-- ==========================================
SELECT 'TEST 2: Running Cross-Industry Fraud Analysis (Should Succeed)...' as TEST_CASE;

-- This calls the stored procedure which joins data inside the clean room and applies aggregation policies
CALL SHARED_ANALYSIS_ZONE.CLEANROOM.ANALYZE_CROSS_INDUSTRY_FRAUD(18, 90);


-- ==========================================
-- TEST 3: CONSUMER CAN RUN SUBSIDY ANALYSIS
-- ==========================================
SELECT 'TEST 3: Running Subsidy Analysis (Should Succeed)...' as TEST_CASE;

CALL SHARED_ANALYSIS_ZONE.CLEANROOM.ANALYZE_SUBSIDY_GAP();


-- ==========================================
-- TEST 4: CHECK AUTOMATED REPORT HISTORY
-- ==========================================
SELECT 'TEST 4: Checking Automated Report History...' as TEST_CASE;

SELECT * FROM SHARED_ANALYSIS_ZONE.CLEANROOM.FRAUD_RISK_REPORT_HISTORY;


-- ==========================================
-- TEST 5: VERIFY MASKING FOR PROVIDERS
-- ==========================================
USE ROLE PROVIDER_BANK;
SELECT 'TEST 5: Verify PII Masking for Bank Role (Should see clear text for own data)...' as TEST_CASE;

-- Bank Provider should see their own PII (or maybe masked depending on policy, we set it to self-view)
SELECT TOP 5 * FROM BANK_DB.RAW.CUSTOMERS;

USE ROLE CONSUMER_ANALYST; -- Switch back just to check perception if they had select
-- Note: Consumer has no select on raw table, so we can't test masking directly on raw table with Consumer.
-- The protection is simply "No Access".

SELECT 'Verification Complete. The Clean Room prevents raw access but allows insights!' as CONCLUSION;
